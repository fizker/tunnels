extension AsyncSequence {
	public func collectAll<S: RangeReplaceableCollection>(as type: S.Type = [Element].self) async rethrows -> S
		where S.Element == Element
	{
		var result = S()
		for try await item in self {
			result.append(item)
		}
		return result
	}
}
