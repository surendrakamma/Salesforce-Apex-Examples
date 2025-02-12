global with sharing class MassMergeAndReparentUsingCsvFile implements Database.Batchable<Id> {
    
    global final Map<Id, List<Id>> masterDuplicateChildMap;
    global final String batchCode;
    
    global MassMergeAndReparentUsingCsvFile(Map<Id, List<Id>> masterDuplicateChildMap,String batchCode) {
        this.masterDuplicateChildMap = masterDuplicateChildMap;
        this.batchCode = batchCode;
    }

    global Iterable<Id> start(Database.BatchableContext bc) {
        return new CustomIterableClass(masterDuplicateChildMap.keySet());
    }
    
    global void execute(Database.BatchableContext bc, List<Id> scope){
        List<Database.MergeResult> mergeResultList = new List<Database.MergeResult>();
        List<Id> lstMergedIds = new List<Id>();
        List<Id> lstFailedIds = new List<Id>();
        Map<Id,String> mapIdWithFailureReason = new Map<Id,String>();
        List<MergeLog__c> mergeLogs = new List<MergeLog__c>();
        
        for(Id masterObjectId: scope){
            system.debug('key--'+masterObjectId);
            if(masterDuplicateChildMap.containsKey(masterObjectId)){
                mergeResultList = Database.merge(masterObjectId.getSObjectType().newSObject(masterObjectId), 
                                                 masterDuplicateChildMap.get(masterObjectId), 
                                                 false);
                for(Database.MergeResult res : mergeResultList) {
                    MergeLog__c log = new MergeLog__c();
                    log.IsSuccess__c = res.isSuccess();
                    log.MasterId__c = res.getId();
                    log.BatchCode__c = batchCode;
                    if(res.isSuccess()){
                        log.MergedRecordIds__c = String.join(res.getMergedRecordIds(),'');
                        log.UpdatedRelatedIds__c = String.join(res.getUpdatedRelatedIds(), ',');
                        log.Error__c = null;
                        
                    }else {
                        for(Database.Error err : res.getErrors()) {
                            log.MergedRecordIds__c = null;
                            log.UpdatedRelatedIds__c = null;
                            log.Error__c = err.getMessage();
                        }
                    }
                    
                    mergeLogs.add(log);
                }        
            }    
        }
        
        if(!mergeLogs.isEmpty()){
            try{
                Database.Insert(mergeLogs,false);
            }Catch(Exception e){
                System.debug('Exception from mergeLogs--'+e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Do any cleanup work here
    }
}
