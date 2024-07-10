trigger FirstCommentTimeTrigger on CaseComment (after insert) {
    // Set to hold case ids with new comments
    Set<Id> caseIds = new Set<Id>();
    for (CaseComment cc : Trigger.New) {
        caseIds.add(cc.ParentId);
    }

    // Query cases to check if they already have a first comment time
    List<Case> casesToUpdate = [SELECT Id, First_Comment_Time__c FROM Case WHERE Id IN :caseIds];

    // List to hold cases that need to be updated
    List<Case> casesToUpdateList = new List<Case>();

    for (Case c : casesToUpdate) {
        // If First_Comment_Time__c is null, set it to current time
        if (c.First_Comment_Time__c == null) {
            c.First_Comment_Time__c = System.now();
            casesToUpdateList.add(c);
        }
    }

    // Update cases with the new first comment time
    if (!casesToUpdateList.isEmpty()) {
        update casesToUpdateList;
    }
}