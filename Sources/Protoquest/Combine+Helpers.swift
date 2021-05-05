import Combine
import HandyOperators

extension Publisher {
	func also(run block: @escaping (Output) -> Void) -> Publishers.Map<Self, Output> {
		map { $0 <- { block($0) } }
	}
}
