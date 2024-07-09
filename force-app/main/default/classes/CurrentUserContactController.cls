public without sharing class CurrentUserContactController {
    @AuraEnabled(cacheable=true)
    public static String getContactId() {
        User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return currentUser.ContactId;
    }
}
