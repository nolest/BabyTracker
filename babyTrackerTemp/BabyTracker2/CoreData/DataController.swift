import Foundation
import CoreData
import Combine

class DataController: ObservableObject {
    static let shared = DataController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "BabyTracker2")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    func save() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("Error saving context: \(error.localizedDescription)")
            }
        }
    }
    
    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
        save()
    }
    
    // MARK: - Baby CRUD
    
    func addBaby(name: String, birthDate: Date, gender: String) -> Baby {
        let baby = Baby(context: container.viewContext)
        baby.id = UUID()
        baby.name = name
        baby.birthDate = birthDate
        baby.gender = gender
        baby.createdAt = Date()
        baby.updatedAt = Date()
        
        save()
        
        return baby
    }
    
    func getAllBabies() -> [Baby] {
        let request: NSFetchRequest<Baby> = Baby.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Baby.name, ascending: true)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching babies: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Activity Queries
    
    func getRecentActivities(for baby: Baby, limit: Int = 10) -> [Activity] {
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.predicate = NSPredicate(format: "baby == %@", baby)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Activity.startTime, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching activities: \(error.localizedDescription)")
            return []
        }
    }
    
    func getTodayActivities(for baby: Baby, type: String? = nil) -> [Activity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        var predicates: [NSPredicate] = [
            NSPredicate(format: "baby == %@", baby),
            NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)
        ]
        
        if let type = type {
            predicates.append(NSPredicate(format: "type == %@", type))
        }
        
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Activity.startTime, ascending: false)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching today's activities: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Statistics
    
    func getActivityStatistics(for baby: Baby, type: String, fromDate: Date) -> [Activity] {
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "baby == %@", baby),
            NSPredicate(format: "type == %@", type),
            NSPredicate(format: "startTime >= %@", fromDate as NSDate)
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Activity.startTime, ascending: true)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching activity statistics: \(error.localizedDescription)")
            return []
        }
    }
    
    func getGrowthRecords(for baby: Baby) -> [GrowthRecord] {
        let request: NSFetchRequest<GrowthRecord> = GrowthRecord.fetchRequest()
        request.predicate = NSPredicate(format: "baby == %@", baby)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GrowthRecord.date, ascending: true)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching growth records: \(error.localizedDescription)")
            return []
        }
    }
}