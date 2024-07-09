trigger FirstAssignTrigger on Case (before update) {
    for (Case c : Trigger.new) {
        Case oldCase = Trigger.oldMap.get(c.Id);

        // First Response Time 필드가 비어있고, Case가 'In Progress' 상태로 변경될 때 기록
        if (c.First_Assign_Time__c == null && oldCase.Status != 'Working' && c.Status == 'Working') {
            c.First_Assign_Time__c = System.now();
        }
    }
}
