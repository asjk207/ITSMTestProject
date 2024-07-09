trigger CompleteResolutionTimeMilestone on Case (after update) {
    //if (UserInfo.getUserType() == 'Standard'){
        DateTime completionDate = System.now(); 
        List<Id> updateCases = new List<Id>();
        System.debug('CompleteResolutionTimeMilestone :  '+updateCases);
        for (Case c : Trigger.new){
            
            System.debug('c.SlaStartDate :  '+c.SlaStartDate);
            System.debug('c.SlaExitDate :  '+c.SlaExitDate);
            System.debug('completionDate :  '+completionDate);
            if (((c.isClosed == true)||(c.Status == 'Closed'))&&((c.SlaStartDate <= completionDate)))
                    updateCases.add(c.Id);
       // }
       System.debug('CompleteResolutionTimeMilestone :  '+updateCases);
    if (updateCases.isEmpty() == false)
        milestoneUtils.completeMilestone(updateCases, completionDate);
    }
}