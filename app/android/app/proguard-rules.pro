# Release builds shrink with R8 in full mode (Flutter applies this file).

# WorkManager (D75) keeps its jobs in a Room database. Room creates the
# generated `_Impl` class through its no-argument constructor by
# reflection; Room 2.6's own rule keeps the class but, in full mode, not
# the constructor, and the app then crashes at launch while WorkManager
# initializes.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
