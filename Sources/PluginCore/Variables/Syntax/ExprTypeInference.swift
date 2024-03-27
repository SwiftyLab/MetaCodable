import SwiftOperators
@_implementationOnly import SwiftSyntax

// Potential future enhancements:
// - .ternaryExpr having "then" and "else" expressions as inferrable types
// - Consider: .isExpr, switchExpr, .tryExpr, .closureExpr

extension ExprSyntax {
    var inferredTypeSyntax: TypeSyntax? {
        self.inferredType?.typeSyntax
    }
}

private indirect enum ExprInferrableType: Equatable, CustomStringConvertible {
    case array(ExprInferrableType)
    case arrayTypeInitializer(elementType: String)
    case `as`(type: String)
    case bool
    case closedRange(ExprInferrableType)
    case dictionary(key: ExprInferrableType, value: ExprInferrableType)
    case dictionaryTypeInitializer(keyType: String, valueType: String)
    case double
    case int
    case range(ExprInferrableType)
    case string
    case tuple([ExprInferrableType])
    case function(type: String)
    
    var description: String {
        switch self {
        case .array(let elementType):
            return "[\(elementType.description)]"
            
        case .arrayTypeInitializer(let elementType):
            return "[\(elementType)]"
            
        case .as(let type):
            return type
            
        case .bool:
            return "Bool"
            
        case .closedRange(let containedType):
            return "ClosedRange<\(containedType.description)>"
            
        case .dictionary(let keyType, let valueType):
            // NB: swift-format prefers `[Key: Value]`, but Xcode uses `[Key : Value]`.
            return "[\(keyType.description): \(valueType.description)]"
            
        case .dictionaryTypeInitializer(let keyType, let valueType):
            return "[\(keyType): \(valueType)]"
            
        case .double:
            return "Double"
            
        case .int:
            return "Int"
            
        case .range(let containedType):
            return "Range<\(containedType.description)>"
            
        case .string:
            return "String"
            
        case .tuple(let elementTypes):
            let typeDescriptions = elementTypes.map(\.description).joined(separator: ", ")
            return "(\(typeDescriptions))"
        case .function(let type):
            return type
        }
    }
    
    var unwrapSingleElementTuple: ExprInferrableType? {
        guard
            case let .tuple(elementTypes) = self,
            elementTypes.count == 1
        else { return nil }
        return elementTypes.first
    }
    
    var typeSyntax: TypeSyntax {
        TypeSyntax(stringLiteral: self.description)
    }
}

enum InfixOperator {
    enum ArithmeticOperator: String {
        case addition = "+"
        case subtraction = "-"
        case multiplication = "*"
        case division = "/"
        case modulo = "%"
    }
    
    enum BitwiseOperator: String {
        case bitwiseAnd = "&"
        case bitwiseOr = "|"
        case bitwiseXor = "^"
        case bitwiseShiftLeft = "<<"
        case bitwiseShiftRight = ">>"
    }
    
    enum LogicalOperator: String {
        case equality = "=="
        case inequality = "!="
        case lessThan = "<"
        case greaterThan = ">"
        case lessThanOrEqual = "<="
        case greaterThanOrEqual = ">="
        case logicalAnd = "&&"
        case logicalOr = "||"
    }
    
    enum RangeOperator: String {
        case closedRange = "..."
        case halfOpenRange = "..<"
    }
    
    case arithmetic(ArithmeticOperator)
    case bitwise(BitwiseOperator)
    case logical(LogicalOperator)
    case range(RangeOperator)
    
    init?(rawValue: String) {
        let type: Self? =
        if let arithmeticOp = ArithmeticOperator(rawValue: rawValue) {
            .arithmetic(arithmeticOp)
        } else if let bitwiseOp = BitwiseOperator(rawValue: rawValue) {
            .bitwise(bitwiseOp)
        } else if let logicalOp = LogicalOperator(rawValue: rawValue) {
            .logical(logicalOp)
        } else if let rangeOp = RangeOperator(rawValue: rawValue) {
            .range(rangeOp)
        } else {
            nil
        }
        guard let type else { return nil }
        self = type
    }
}

extension ExprSyntax {
    private var inferredType: ExprInferrableType? {
        switch self.kind {
        case .arrayExpr:
            guard let arrayExpr = self.as(ArrayExprSyntax.self) else { return nil }
            
            let elementTypes = arrayExpr.elements.compactMap { $0.expression.inferredType }
            guard
                elementTypes.count == arrayExpr.elements.count,
                let firstType = elementTypes.first,
                let inferredArrayType = elementTypes.dropFirst().reduce(firstType, { commonType($0, $1) })
            else { return nil }
            return .array(inferredArrayType)
            
        case .asExpr:
            guard let asExpr = self.as(AsExprSyntax.self) else { return nil }
            return .as(type: asExpr.type.trimmedDescription)
            
        case .booleanLiteralExpr:
            return .bool
            
        case .dictionaryExpr:
            guard let dictionaryExpr = self.as(DictionaryExprSyntax.self) else { return nil }
            
            let keyValuePairs =
            dictionaryExpr.content
                .as(DictionaryElementListSyntax.self)?
                .compactMap { ($0.key.inferredType, $0.value.inferredType) }
            ?? []
            
            guard !keyValuePairs.isEmpty else { return nil }
            
            let initialKeyTypes = keyValuePairs.map(\.0)
            let initialValueTypes = keyValuePairs.map(\.1)
            
            guard
                let firstKeyType = initialKeyTypes.first,
                let firstValueType = initialValueTypes.first,
                let inferredKeyType = initialKeyTypes.dropFirst().reduce(
                    firstKeyType, { commonType($0, $1) }),
                let inferredValueType = initialValueTypes.dropFirst().reduce(
                    firstValueType, { commonType($0, $1) })
            else { return nil }
            
            return .dictionary(key: inferredKeyType, value: inferredValueType)
            
        case .floatLiteralExpr:
            return .double
            
        case .functionCallExpr:
            guard let functionCallExpr = self.as(FunctionCallExprSyntax.self) else { return nil }
            
            // NB: `[Type]()`
            if let arrayExpr = functionCallExpr.calledExpression.as(ArrayExprSyntax.self) {
                let typeString = arrayExpr.elements
                    .first?
                    .expression
                    .as(DeclReferenceExprSyntax.self)?
                    .baseName
                    .trimmedDescription
                guard let typeString else { return nil }
                return .arrayTypeInitializer(elementType: typeString)
            }
            
            // NB: `[KeyType : ValueType]()`
            if let dictionaryExpr = functionCallExpr.calledExpression.as(DictionaryExprSyntax.self) {
                guard let type = dictionaryExpr.content.as(DictionaryElementListSyntax.self)?.first
                else { return nil }
                
                return .dictionaryTypeInitializer(
                    keyType: type.key.trimmedDescription,
                    valueType: type.value.trimmedDescription
                )
            }
            
            return .function(type: functionCallExpr.calledExpression.description)
            
        case .infixOperatorExpr:
            guard
                let infixOperatorExpr = self.as(InfixOperatorExprSyntax.self),
                let lhsType = infixOperatorExpr.leftOperand.as(ExprSyntax.self)?.inferredType,
                let rhsType = infixOperatorExpr.rightOperand.as(ExprSyntax.self)?.inferredType,
                let operation = InfixOperator(rawValue: infixOperatorExpr.operator.trimmedDescription),
                let inferredType = resultTypeOfInfixOperation(
                    lhs: lhsType,
                    rhs: rhsType,
                    operation: operation
                )
            else { return nil }
            return inferredType
            
        case .integerLiteralExpr:
            return .int
            
        case .prefixOperatorExpr:
            guard
                let prefixOperatorExpr = self.as(PrefixOperatorExprSyntax.self)
            else { return nil }
            return prefixOperatorExpr.expression.inferredType
            
        case .sequenceExpr:
            // NB: SwiftSyntax 509.0.2 represents `1 + 2 + 3` as a tree of InfixOperatorExprSyntax
            // values, but Swift 5.9.0 represents it as SequenceExprSyntax.
            guard
                let sequenceExpr = self.as(SequenceExprSyntax.self),
                let foldedExpr = try? OperatorTable.standardOperators.foldSingle(sequenceExpr)
            else { return nil }
            return foldedExpr.inferredType
            
        case .stringLiteralExpr, .simpleStringLiteralExpr, .simpleStringLiteralSegmentList,
                .stringLiteralSegmentList:
            return .string
            
        case .tupleExpr:
            guard let tupleExpr = self.as(TupleExprSyntax.self) else { return nil }
            let elementTypes = tupleExpr.elements.compactMap { $0.expression.inferredType }
            guard elementTypes.count == tupleExpr.elements.count
            else { return nil }
            return .tuple(elementTypes)
            
        case .memberAccessExpr:
            return nil
        default: return nil
        }
    }
}

private func commonType(
    _ first: ExprInferrableType?,
    _ second: ExprInferrableType?
) -> ExprInferrableType? {
    guard let firstType = first, let secondType = second else { return nil }
    
    switch (firstType, secondType) {
    case (.as(let firstElementType), .as(let secondElementType)):
        return firstElementType == secondElementType ? firstType : nil
        
    case (.int, .double), (.double, .int):
        return .double
        
    case (.int, .int):
        return .int
        
    case (.double, .double):
        return .double
        
    case (.string, .string):
        return .string
        
    case (.bool, .bool):
        return .bool
        
    case (.array(let firstElementType), .array(let secondElementType)):
        if let commonElementType = commonType(firstElementType, secondElementType) {
            return .array(commonElementType)
        }
        
    case (
        .dictionary(let firstKeyType, let firstValueType),
        .dictionary(let secondKeyType, let secondValueType)
    ):
        if let commonKeyType = commonType(firstKeyType, secondKeyType),
           let commonValueType = commonType(firstValueType, secondValueType)
        {
            return .dictionary(key: commonKeyType, value: commonValueType)
        }
        
    case (.closedRange(let firstContainedType), .closedRange(let secondContainedType)):
        if let commonContainedType = commonType(firstContainedType, secondContainedType) {
            return .closedRange(commonContainedType)
        }
        
    case (.range(let firstContainedType), .range(let secondContainedType)):
        if let commonContainedType = commonType(firstContainedType, secondContainedType) {
            return .range(commonContainedType)
        }
        
    default:
        return nil
    }
    
    return nil
}

private func resultTypeOfInfixOperation(
    lhs: ExprInferrableType,
    rhs: ExprInferrableType,
    operation: InfixOperator
) -> ExprInferrableType? {
    let lhsType = lhs.unwrapSingleElementTuple ?? lhs
    let rhsType = rhs.unwrapSingleElementTuple ?? rhs
    
    switch operation {
    case .logical(_):
        return .bool
        
    case .arithmetic(let op):
        switch op {
        case .addition, .subtraction, .multiplication, .division:
            return commonType(lhsType, rhsType)
            
        case .modulo:
            return (lhsType, rhsType) == (.int, .int) ? .int : nil
        }
        
    case .range(let op):
        guard let type = commonType(lhsType, rhsType) else { return nil }
        return switch op {
        case .closedRange:
            ExprInferrableType.closedRange(type)
            
        case .halfOpenRange:
                .range(type)
        }
        
    case .bitwise(_):
        guard (lhsType, rhsType) == (.int, .int) else { return nil }
        return .int
    }
}
