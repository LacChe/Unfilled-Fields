@isTest
public with sharing class FieldUsageScannerTest {
    
    @isTest static void testFieldUsageScannerPayload(){
		FieldUsageScanner.FieldUsageScannerPayload payload = FieldUsageScanner.getAllQueriedFieldsAndRecordsWithEmptyFields();
        System.assertEquals(payload.records, FieldUsageScanner.getRecordsWithEmptyFields(), 'Payload records property should be same as parent class static property.');
        System.assertEquals(payload.fields, FieldUsageScanner.getAllQueriedFields(), 'Payload fields property should be same as parent class static property.');
    }
    
    @isTest static void testScanForQueriedRecordsWithNullFields(){
        List<Account> accounts = new List<Account> {
            new Account(Name='TestAccount0'),
            new Account(Name='TestAccount1')
        };
        insert accounts;
        String body = '[SELECT Name, Phone FROM Account]';
        FieldUsageScanner.scanTextForQueries(body);
        FieldUsageScanner.scanForQueriedRecordsWithNullFields();
        Map<String, Map<ID, List<String>>> recordsWithEmptyFields = FieldUsageScanner.getRecordsWithEmptyFields();
        System.assert(recordsWithEmptyFields.containsKey('account'), 'Should contain sObject name: account as key.');
        System.assert(recordsWithEmptyFields.get('account').containsKey(accounts.get(0).ID), 'Should contain Account ID: ' + accounts.get(0).ID + ' as second key.');
        System.assert(recordsWithEmptyFields.get('account').containsKey(accounts.get(1).ID), 'Should contain Account ID: ' + accounts.get(1).ID + ' as second key.');
    }
    
    @isTest static void testScanTextForQueries(){
        String body = '[SELECT Name Account.Name count() FROM Contact]' + 
            '[SELECT Name Account.Name count() FROM Contact]' + 
            '[SELECT Name Account.Name count() FROM Contact]' + 
            '[SELECT Name Account.Name count() FROM Contact]';
        List<String> fields = new List<String>{
            'select','name','account.name','count','from','contact'
        };
        FieldUsageScanner.scanTextForQueries(body);
        Map<String, Map<String, Integer>> allQueriedFields = FieldUsageScanner.getAllQueriedFields();
        System.debug(allQueriedFields);
		System.assert(allQueriedFields.containsKey(fields[5]), 'Should contain sObject name: ' + fields[5] + ' as key.');
		System.assert(allQueriedFields.get(fields[5]).containsKey(fields[1]), 'Should contain field name: ' + fields[1] + ' as second key.');
        System.assertEquals(allQueriedFields.get(fields[5]).get(fields[1]), 4, 'Should have count of ' + 4 + ' queried.');
        System.assert(allQueriedFields.containsKey(fields[2].split('\\.')[0]), 'Should contain sObject name: ' + fields[2].split('\\.')[0] + ' as key.');
		System.assert(allQueriedFields.get(fields[2].split('\\.')[0]).containsKey(fields[2].split('\\.')[1]), 'Should contain field name: ' + fields[2].split('\\.')[1] + ' as second key.');
    }
    
    @isTest static void testMapFields(){
        List<String> fields = new List<String>{
            'SELECT','Name','Account.Name','count','FROM','Contact'
        };
        for(Integer i = 0; i < 4; i++){
            FieldUsageScanner.mapFields(fields);
        }
        Map<String, Map<String, Integer>> allQueriedFields = FieldUsageScanner.getAllQueriedFields();
		System.assert(allQueriedFields.containsKey(fields[5]), 'Should contain sObject name: ' + fields[3] + ' as key.');
		System.assert(allQueriedFields.get(fields[5]).containsKey(fields[1]), 'Should contain field name: ' + fields[1] + ' as second key.');
        System.assertEquals(allQueriedFields.get(fields[5]).get(fields[1]), 4, 'Should have count of ' + 4 + ' queried.');
        System.assert(allQueriedFields.containsKey(fields[2].split('\\.')[0]), 'Should contain sObject name: ' + fields[2].split('\\.')[0] + ' as key.');
		System.assert(allQueriedFields.get(fields[2].split('\\.')[0]).containsKey(fields[2].split('\\.')[1]), 'Should contain field name: ' + fields[2].split('\\.')[1] + ' as second key.');
    }

    @isTest static void testRemoveComments(){
        
        String original = 'Lorem ipsum dolor sit amet,\n' + 
            'consectetur adipiscing elit.\n' +
            'Sed lacinia felis tortor,\n' +
            'ac gravida velit suscipit nec.\n';
        FieldUsageScanner.currentString = original;
        FieldUsageScanner.removeComments();
        System.assertEquals(original, FieldUsageScanner.currentString, 'Nothing should be changed.');
        
        String singleLineComment = 'Lorem ipsum dolor sit amet,\n' + 
            'consectetur adipiscing elit.\n' +
            '// singleLineComment \n' +
            'Sed lacinia felis tortor,\n' +
            'ac gravida velit suscipit nec.\n';
        FieldUsageScanner.currentString = singleLineComment;
        FieldUsageScanner.removeComments();
        System.assertEquals(original, FieldUsageScanner.currentString, 'Single line comments should be removed.');        
        
        String singleLineCommentWithNoEndline = 'Lorem ipsum dolor sit amet,\n' + 
            'consectetur adipiscing elit.\n' +
            'Sed lacinia felis tortor,\n' +
            'ac gravida velit suscipit nec.\n' +
            '// singleLineCommentWithNoEndline.';
        FieldUsageScanner.currentString = singleLineCommentWithNoEndline;
        FieldUsageScanner.removeComments();
        System.assertEquals(singleLineCommentWithNoEndline, FieldUsageScanner.currentString, 'Nothing should be changed.');
        
        String multiLineComment = 'Lorem ipsum dolor sit amet,\n' + 
            'consectetur adipiscing elit.\n' +
            '/* \n' +
            '* multiLineCommentLineComment \n' +
            '* multiLineCommentLineComment \n' +
            '* multiLineCommentLineComment \n' +
            '*/ \n' +
            'Sed lacinia felis tortor,\n' +
            'ac gravida velit suscipit nec.\n';
        FieldUsageScanner.currentString = multiLineComment;
        FieldUsageScanner.removeComments();        
        System.assertEquals(original, FieldUsageScanner.currentString, 'Multi line comments should be removed.');  
        
        String multiLineCommentWithoutEnd = 'Lorem ipsum dolor sit amet,\n' + 
            'consectetur adipiscing elit.\n' +
            '/* \n' +
            '* multiLineCommentLineComment \n' +
            '* multiLineCommentLineComment \n' +
            '* multiLineCommentLineComment \n' +
            '\n' +
            'Sed lacinia felis tortor,\n' +
            'ac gravida velit suscipit nec.\n';
        FieldUsageScanner.currentString = multiLineCommentWithoutEnd;
        FieldUsageScanner.removeComments();        
        System.assertEquals(multiLineCommentWithoutEnd, FieldUsageScanner.currentString, 'Nothing should be changed.');
        
    }
    
}