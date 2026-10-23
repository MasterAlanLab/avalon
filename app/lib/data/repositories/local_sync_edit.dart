/// Called inside the transaction that saves a user edit. Background refreshes
/// and automatic selector changes do not create Cloud mutations.
typedef LocalSyncEdit =
    Future<void> Function(String type, String localId, bool deleted);
