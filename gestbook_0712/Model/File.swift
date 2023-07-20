import Foundation

import RealmSwift

class ItemTable: Object {
    @Persisted var id: String = ""
    @Persisted var name: String = ""
    @Persisted var message: String = ""
    @Persisted var sortID: Int = 1
}
