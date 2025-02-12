public class MergeControllerForBatchApex {
    
	public Static Map<Id, List<Id>> mapMasterDuplicateChild = new Map<Id, List<Id>>();
	//public Static Integer batchSize = 200; // Set the batch size
    public Static List<Map<Id, List<Id>>> scopeMaps = new List<Map<Id, List<Id>>>();
    
    public Static void getMasterDuplicateMapFromCsv(Id latestContentDocumentId){
        String batchCode = 'OCT190231AM';
        Set<Id> masterIdsAdded = new Set<Id>();
        Map<Id, List<Id>> currentScopeMap = new Map<Id, List<Id>>();
        
        // Fetch CSV Rows
        ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId =: latestContentDocumentId AND IsLatest = true];
        String contentVersionToString = cv.VersionData.toString(); 
        String[] csvRows = contentVersionToString.split('\n');
        // Build Master-Child Map from CSV Rows
        // Using i=1 to avoid Header Row at 0 index
        for(Integer i=1; i < csvRows.size() ; i++){
            List<String> stringIds = new List<String>();
            List<Id> duplicateChildRecordIds = new List<Id>();
            list<String> csvColumns = new list<String>();
            csvColumns = csvRows[i].split(',');
            
            // csv file has 2 Columns, where 0 = Master Object Id, 1 = Duplicate Object Id List
            Id masterObjectId = csvColumns[0].trim();
            stringIds = csvColumns[1].trim().split(';');
            duplicateChildRecordIds = (List<Id>)stringIds;
            mapMasterDuplicateChild.put(masterObjectId, duplicateChildRecordIds);  
        }
        
        if(!mapMasterDuplicateChild.isEmpty()){
            MassMergeAndReparentUsingCsvFile mergeBatch = new MassMergeAndReparentUsingCsvFile(mapMasterDuplicateChild,batchCode);
            Database.executeBatch(mergeBatch, 25);
        }
        
		// Generate a list of scope maps for each batch
		/*
        for (Id masterId : mapMasterDuplicateChild.keySet()) {
            if (!masterIdsAdded.contains(masterId)) {
                List<Id> duplicateIds = mapMasterDuplicateChild.get(masterId);
                currentScopeMap.put(masterId, duplicateIds);
                masterIdsAdded.add(masterId);
            }
            if (currentScopeMap.keySet().size() == batchSize) {
                scopeMaps.add(currentScopeMap);
                currentScopeMap = new Map<Id, List<Id>>();
                masterIdsAdded.clear();
            }
        }
        // For the last set of records which are less than batchSize
        if (currentScopeMap.keySet().size() > 0) {
            scopeMaps.add(currentScopeMap);
        }
        
        // Process each scope map batch using the merge batch class
        for (Map<Id, List<Id>> scopeMap : scopeMaps) {
            MassMergeAndReparentUsingCsvFile mergeBatch = new MassMergeAndReparentUsingCsvFile(scopeMap,batchCode);
            Database.executeBatch(mergeBatch, 25);
    	}
		*/
    }

}
