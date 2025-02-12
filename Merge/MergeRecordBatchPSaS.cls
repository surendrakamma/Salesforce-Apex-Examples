/************************************************************************************
 * Class: MergeRecordBatchPSaS
 * Purpose: To Merge the Sobject(Account, Contact & Lead) stored in
 * 			Merge_Records__c custom Settings(MasterId, List<DuplicateChildId>)
 * Execution: We invoke this class from Anonymous Window with below code
 * 
 * 			MergeRecordBatchPSaS batch = new MergeRecordBatchPSaS('batchCode');
 *			Database.executeBatch(batch,25);
 * Parameters: String batchCode = To identify all the MergeLogs with this batchCode.
 * 			   Integer batchSize in the executeBatch() is required and depends on the Sobject
 * 			Eg. for Account the max batch side = 25 so that we don't get any errors
 * Author: Surendra Kamma
 *************************************************************************************/
global class MergeRecordBatchPSaS implements Database.Batchable<Sobject> {
    global String batchCode;
    
    global MergeRecordBatchPSaS(String batchCode) {
        this.batchCode = batchCode;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('Select Id,MasterId__c,DuplicateChildIds__c from Merge_Record__c');
    }
    
    global void execute(Database.BatchableContext bc, List<Sobject> scope){
        
        System.debug('scopeSize--'+scope.size());
        List<Database.MergeResult> mergeResultList = new List<Database.MergeResult>();
        Map<Account, List<Id>> mapMasterDuplicateChilds = new Map<Account, List<Id>>();
        Map<Id,String> mapIdWithFailureReason = new Map<Id,String>();
        List<MergeLog__c> mergeLogs = new List<MergeLog__c>();
        List<Id> lstMergedIds = new List<Id>();
        List<Id> lstFailedIds = new List<Id>();
        for(Sobject mergeRecord : scope){
            List<Id> duplicateIdList = new List<Id>();
            Id masterId = (Id)mergeRecord.get('MasterId__c');
            String duplicateChilds = (String)mergeRecord.get('DuplicateChildIds__c');
            duplicateIdList = duplicateChilds.trim().split(';');
            mergeResultList = Database.merge(masterId.getSObjectType().newSObject(masterId), 
                                             duplicateIdList, false);
            
            for(Database.MergeResult res : mergeResultList) {
                MergeLog__c log = new MergeLog__c();
                log.IsSuccess__c = res.isSuccess();
                log.MasterId__c = res.getId();
                log.BatchCode__c = batchCode;
                if(res.isSuccess()){
                    log.MergedRecordIds__c = String.join(res.getMergedRecordIds(),',');
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
        
        if(!mergeLogs.isEmpty()){
            Database.Insert(mergeLogs,false);
        }
    }
                                        
    global void finish(Database.BatchableContext bc){}
}
