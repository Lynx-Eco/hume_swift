import Foundation

/// Direction for pagination
public enum PaginationDirection: String, Codable, Sendable {
    case asc
    case desc
}

/// Paginated response wrapper
public struct PagedResponse<T: Codable>: Codable {
    public let pageNumber: Int
    public let pageSize: Int
    public let totalPages: Int
    public let totalItems: Int
    public let items: [T]
    
    private enum CodingKeys: String, CodingKey {
        case pageNumber = "page_number"
        case pageSize = "page_size"
        case totalPages = "total_pages"
        case totalItems = "total_items"
        case items
    }
}

/// Async sequence for paginated results
public struct PaginatedSequence<T: Codable>: AsyncSequence {
    public typealias Element = T
    
    private let fetchPage: (Int) async throws -> PagedResponse<T>
    private let pageSize: Int
    
    public init(
        pageSize: Int,
        fetchPage: @escaping (Int) async throws -> PagedResponse<T>
    ) {
        self.pageSize = pageSize
        self.fetchPage = fetchPage
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(fetchPage: fetchPage, pageSize: pageSize)
    }
    
    public struct AsyncIterator: AsyncIteratorProtocol {
        private let fetchPage: (Int) async throws -> PagedResponse<T>
        private let pageSize: Int
        private var currentPage = 0
        private var currentItems: [T] = []
        private var currentIndex = 0
        private var totalPages: Int?
        
        init(fetchPage: @escaping (Int) async throws -> PagedResponse<T>, pageSize: Int) {
            self.fetchPage = fetchPage
            self.pageSize = pageSize
        }
        
        public mutating func next() async throws -> T? {
            // Check if we have items in the current batch
            if currentIndex < currentItems.count {
                let item = currentItems[currentIndex]
                currentIndex += 1
                return item
            }
            
            // Check if we've fetched all pages
            if let total = totalPages, currentPage >= total {
                return nil
            }
            
            // Fetch next page
            let response = try await fetchPage(currentPage)
            totalPages = response.totalPages
            currentItems = response.items
            currentIndex = 0
            currentPage += 1
            
            // Return first item from new page if available
            if !currentItems.isEmpty {
                currentIndex = 1
                return currentItems[0]
            }
            
            return nil
        }
    }
}

/// Convenience methods for working with paginated responses
public extension PagedResponse {
    /// Check if there are more pages
    var hasNextPage: Bool {
        return pageNumber < totalPages - 1
    }
    
    /// Check if there are previous pages
    var hasPreviousPage: Bool {
        return pageNumber > 0
    }
    
    /// Get the next page number
    var nextPageNumber: Int? {
        return hasNextPage ? pageNumber + 1 : nil
    }
    
    /// Get the previous page number
    var previousPageNumber: Int? {
        return hasPreviousPage ? pageNumber - 1 : nil
    }
}

/// Alternative paginated response format used by some endpoints
public struct PagedResponseAlt<T: Codable>: Codable {
    public let data: [T]
    public let pagination: PaginationInfo
}

public struct PaginationInfo: Codable {
    public let pageNumber: Int
    public let pageSize: Int
    public let totalPages: Int
    public let totalItems: Int
    
    private enum CodingKeys: String, CodingKey {
        case pageNumber = "page_number"
        case pageSize = "page_size"
        case totalPages = "total_pages"
        case totalItems = "total_items"
    }
}

/// Convert alternative format to standard format
public extension PagedResponseAlt {
    func toStandardFormat() -> PagedResponse<T> {
        return PagedResponse(
            pageNumber: pagination.pageNumber,
            pageSize: pagination.pageSize,
            totalPages: pagination.totalPages,
            totalItems: pagination.totalItems,
            items: data
        )
    }
}