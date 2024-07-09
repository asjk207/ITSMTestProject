public without sharing class CaseController {

    @AuraEnabled
    public static void createCaseWithFiles(String subject, String description, String priority, String product, List<String> contentDocumentIds) {
        Case newCase = new Case(
            Subject = subject,
            Description = description,
            Priority = priority,
            Product__c = product
        );
    
        // DMLOptions 설정
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.useDefaultRule = true; // 기본 할당 규칙 사용
    
        try {
            // Insert the case using assignment rules
            Database.SaveResult caseResult = Database.insert(newCase, dmlOpts);
    
            if (caseResult.isSuccess()) {
                // Retrieve the ID from caseResult
                String newCaseId = caseResult.getId();
                System.debug('New case created successfully. Case ID: ' + newCaseId);
    
                // Insert ContentDocumentLink records
                List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
                for (String contentDocumentId : contentDocumentIds) {
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = contentDocumentId;
                    cdl.LinkedEntityId = newCaseId;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    contentDocumentLinks.add(cdl);
                }
                insert contentDocumentLinks;
    
                System.debug('ContentDocumentLinks inserted successfully.');
    
                // Retrieve the updated Case with OwnerId set by assignment rules
                Case insertedCase = [SELECT Id, OwnerId, Subject, Description FROM Case WHERE Id = :newCaseId LIMIT 1];
    
                // Check if the OwnerId is valid
                if (insertedCase.OwnerId != null) {
                    // Retrieve the Case Owner's Email
                    List<User> caseOwners = [SELECT Email FROM User WHERE Id = :insertedCase.OwnerId LIMIT 1];
                    if (!caseOwners.isEmpty() && caseOwners[0].Email != null && caseOwners[0].Email != '') {
                        String caseOwnerEmail = caseOwners[0].Email;
                        // Send Email
                        sendEmailToCaseOwner(caseOwnerEmail, insertedCase.Subject, insertedCase.Description, insertedCase.Id);
                    } else {
                        System.debug('Case Owner does not have a valid email address.');
                    }
                } else {
                    System.debug('Case does not have a valid OwnerId.');
                }
            } else {
                // Log an error or handle the situation when case creation fails
                for (Database.Error error : caseResult.getErrors()) {
                    System.debug('Error creating case: ' + error.getMessage());
                }
            }
        } catch (Exception e) {
            System.debug('Error in createCaseWithFiles: ' + e.getMessage());
        }
    }

    private static void sendEmailToCaseOwner(String caseOwnerEmail, String caseSubject, String caseDescription, String caseId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { caseOwnerEmail });
        /*mail.setSubject('New Case Created: ' + caseSubject);
        mail.setPlainTextBody('A new case has been created with the following details:\n\n' +
                              'Subject: ' + caseSubject + '\n' +
                              'Description: ' + caseDescription + '\n\n' +
                              'Please log in to Salesforce to view further details.');*/
        mail.setSubject('사례가 생성 되었습니다.');
        mail.setPlainTextBody('A new case has been created with the following details:\n\n' +
                              'Subject: ' + caseSubject + '\n' +
                              'Description: ' + caseDescription + '\n\n' +
                              'Please log in to Salesforce to view further details.'+
                              'https://brave-bear-8ckp37-dev-ed.trailblaze.lightning.force.com/lightning/r/Case/'+caseId+'/view');

        // Set the organization-wide email address ID
        List<OrgWideEmailAddress> orgWideEmails = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'hakuri456@gmail.com' LIMIT 1];
        if (!orgWideEmails.isEmpty()) {
            mail.setOrgWideEmailAddressId(orgWideEmails[0].Id);
        } else {
            System.debug('Organization-Wide Email Address not found.');
            return;
        }

        // Optionally set reply-to and sender display name
        mail.setReplyTo('jh.yoon@echoit.co.kr');
        //mail.setSenderDisplayName('jaehakyoon');
    
        try {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            for (Messaging.SendEmailResult result : results) {
                if (!result.isSuccess()) {
                    System.debug('Failed to send email: ' + result.getErrors()[0].getMessage());
                } else {
                    System.debug('Email sent successfully.');
                }
            }
        } catch (Exception e) {
            System.debug('Exception occurred while sending email: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void closeCase(Id caseId) {
        Case caseRecord = [SELECT Id, Status FROM Case WHERE Id = :caseId LIMIT 1];
        caseRecord.Status = 'Closed';
        update caseRecord;
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getCases(String status) {

        // 현재 사용자 정보 가져오기
        User userInfo = UserController.getUserInfo();
        if (userInfo.AccountId == null || userInfo.ContactId == null) {
            throw new IllegalArgumentException('User does not have associated Account or Contact');
        }

        Id accountId = userInfo.AccountId;
        System.debug('Fetching comments for accountId: ' + accountId); // 디버깅
        Id contactId = userInfo.ContactId;
        System.debug('Fetching comments for contactId: ' + contactId); // 디버깅

        String query = 'SELECT Id, CaseNumber, Subject, Status, LastModifiedDate, Contact.Name FROM Case WHERE Id != null';
        if (accountId != null) {
            query += ' AND AccountId = \'' + accountId + '\'';
        }
        if (contactId != null) {
            // 'Customer Community Plus User' Profile은 고객사 담당자에게 부여
            // 고객사 담당자는 같은 Account의 모든 Case를 볼수 있어야 한다.
            if(userInfo.Profile.Name != 'Customer Community Plus User'){
                query += ' AND ContactId = \'' + contactId + '\'';
            }
        }
        if (status != null && status != '') {
            query += ' AND Status =\'' + status + '\'';
        }
        query += ' LIMIT 100';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<CaseComment> getCaseComments(Id caseId) {
        System.debug('Fetching comments for caseId: ' + caseId); // 디버깅
        return [
            SELECT Id, CommentBody, CreatedDate, CreatedBy.Name 
            FROM CaseComment 
            WHERE ParentId = :caseId 
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static CaseComment addCaseComment(Id caseId, String commentBody) {
        System.debug('Adding comment to caseId: ' + caseId); // 디버깅
        CaseComment newComment = new CaseComment(
            ParentId = caseId,
            CommentBody = commentBody
        );
        insert newComment;
        return newComment;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getCaseCount(String status) {
        if (String.isBlank(status)) {
            throw new IllegalArgumentException('Invalid parameters');
        }
        // 현재 사용자 정보 가져오기
        User userInfo = UserController.getUserInfo();
        if (userInfo.AccountId == null || userInfo.ContactId == null) {
            throw new IllegalArgumentException('User does not have associated Account or Contact');
        }

        Id accountId = userInfo.AccountId;
        System.debug('Fetching comments for accountId: ' + accountId); // 디버깅
        Id contactId = userInfo.ContactId;
        System.debug('Fetching comments for contactId: ' + contactId); // 디버깅

        // 동적 쿼리 작성
        String query = 'SELECT COUNT(Id) FROM Case WHERE Status = \'' + String.escapeSingleQuotes(status) + '\'';

        if (accountId != null) {
            query += ' AND AccountId = \'' + accountId + '\'';
        }
        if (contactId != null) {
            // 'Customer Community Plus User' Profile은 고객사 담당자에게 부여
            // 고객사 담당자는 같은 Account의 모든 Case를 볼수 있어야 한다.
            if(userInfo.Profile.Name != 'Customer Community Plus User'){
                query += ' AND ContactId = \'' + contactId + '\'';
            }
        }
        
        // 쿼리 실행
        List<AggregateResult> results = Database.query(query);

        if (results.isEmpty()) {
            return 0;
        } else {
            return (Integer) results[0].get('expr0');
        }
    }
}
