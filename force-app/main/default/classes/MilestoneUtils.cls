public class MilestoneUtils {
    public static void completeMilestone(List<Id> caseIds, DateTime complDate) {  
    List<CaseMilestone> cmsToUpdate = [SELECT Id, completionDate
            FROM CaseMilestone cm
            WHERE caseId in :caseIds 
            AND completionDate = null limit 1];
    if (cmsToUpdate.isEmpty() == false){
        for (CaseMilestone cm : cmsToUpdate){
            cm.completionDate = complDate;
            }
            System.debug('cmsToUpdate :  '+cmsToUpdate);

        update cmsToUpdate;
        }
    }
}