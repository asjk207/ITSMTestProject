public with sharing class UserController {

    @AuraEnabled(cacheable=true)
    public static User getUserInfo() {
        Id currentUserId = UserInfo.getUserId();
        return [
            SELECT Id, Name, Email, AccountId, ContactId, Title,
                   Phone, Department, ProfileId, Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        /*
        Map<String, Object> userInfoMap = new Map<String, Object>();
        userInfoMap.put('Id', currentUser.Id);
        userInfoMap.put('Name', currentUser.Name);
        userInfoMap.put('Email', currentUser.Email);
        userInfoMap.put('AccountId', currentUser.AccountId);
        userInfoMap.put('ContactId', currentUser.ContactId);
        userInfoMap.put('Title', currentUser.Title);
        userInfoMap.put('Phone', currentUser.Phone);
        userInfoMap.put('Department', currentUser.Department);
        userInfoMap.put('ProfileId', currentUser.ProfileId);
        userInfoMap.put('ProfileName', currentUser.Profile.Name);

        return userInfoMap;*/
    }
    
}