public with sharing class FieldUsageScanner {
    
    // todo 
    // skip this class classname should be dynamic?
    // add subquery functionality, find correct singular name of sobject in subqueries
    // add database.query functionality
    // check if user has access to read fields in database.query
    
    private static final Set<String> AGGREGATE_KEYWORDS = new Set<String>{'avg', 'count', 'min', 'max', 'sum'};
    @TestVisible private static String currentString = '';
    private static final Integer QUERY_LIMIT = 20000;

    // <sobject name, <field name, use count>>
    private static Map<String, Map<String, Integer>> allQueriedFields = new Map<String, Map<String, Integer>>();
    
    // <sobject name, <record id, list of empty fields>>
    private static Map<String, Map<ID, List<String>>> recordsWithEmptyFields = new Map<String, Map<ID, List<String>>>();
    
    @AuraEnabled(cacheable=true)
    public static FieldUsageScannerPayload getAllQueriedFieldsAndRecordsWithEmptyFields(){
        scanForQueriedFields();
        scanForQueriedRecordsWithNullFields();
        FieldUsageScannerPayload payload = new FieldUsageScannerPayload();
        return payload;
    }
    
    public static Map<String, Map<String, Integer>> getAllQueriedFields(){
        return allQueriedFields;
    }
    
    public static Map<String, Map<ID, List<String>>> getRecordsWithEmptyFields(){
        return recordsWithEmptyFields;
    }
	
    public static void scanForQueriedRecordsWithNullFields(){
        
        // scan all queried sObjects
        for(String sObjectName : allQueriedFields.keySet()){
            
            // get fields to query
            Set<String> queriedFields = allQueriedFields.get(sObjectName).keySet();
            String fields = '';
            for(String fieldName : queriedFields){
                fields += fieldName + ', ';
            }
            // remove last comma
            fields = fields.substring(0, fields.length() - 2);
            
            // query fields for this sObject
            String q = 'SELECT ' + fields + ' FROM ' + sObjectName + ' LIMIT ' + QUERY_LIMIT;
            // implement security check here
            List<SObject> records = Database.query(String.escapeSingleQuotes(q));
            

            // check all records
            for(SObject record : records){
    
                // get queried fields containing values and set to lower case
                Set<String> nonNullFields = new Set<String>();
                for(String key : record.getPopulatedFieldsAsMap().keySet()){
                    nonNullFields.add(key.toLowerCase());
                }
                    
                // if field is not in nonNullFields list, then value must be null and add name to nullFields list
                List<String> nullFields = new List<String>();
                for(String field : queriedFields){
                    if(!nonNullFields.contains(field)){
                        nullFields.add(field);
                    }
                }
                    
                // if any null values are found, map to record id
                if(nullFields.Size() > 0){
                    Map<ID, List<String>> nullFieldsOfRecords;
                    if(recordsWithEmptyFields.containsKey(sObjectName)){
                        nullFieldsOfRecords = recordsWithEmptyFields.get(sObjectName);
                    }
                    if(nullFieldsOfRecords == null){
                        nullFieldsOfRecords = new Map<ID, List<String>>();
                    }
                    
                    // add set fields to id, then record to sobject
                    nullFieldsOfRecords.put(record.ID, nullFields);
                    recordsWithEmptyFields.put(sObjectName, nullFieldsOfRecords);
                }

            }
        }
        
    }
    
    public static void scanForQueriedFields(){

        // scan classes
        for(ApexClass c : [select Body from ApexClass WHERE Name != 'FieldUsageScanner' WITH SECURITY_ENFORCED LIMIT :QUERY_LIMIT]){
            scanTextForQueries(c.Body);
        }
        
        // scan triggers
        for(ApexTrigger t : [select Body from ApexTrigger WITH SECURITY_ENFORCED LIMIT :QUERY_LIMIT]){
            scanTextForQueries(t.Body);
        }
    }
    
    @TestVisible
    private static void scanTextForQueries(String body){
        
            currentString = body.toLowerCase();
            
            removeComments();
            
            // find everything within brackets
            Integer startIndex = currentString.indexOf('[');
            Integer endIndex = currentString.indexOf(']');
            while (!(startIndex == -1 || endIndex == -1 || endIndex <= startIndex)){
    
                // extract bracket expression
                String query = currentString.substring(startIndex, endIndex + 1);
                
                // if is query, then organize queried fields
                if(Pattern.matches('\\[\\s*select.*from.*\\]', query)){
                    
                    // remove commas and extra spaces
                    query = query.replaceAll(',|\\s+', ' ');
                    
                    // check for subqueries
                    Integer startIndexP = query.indexOf('(');
                    Integer endIndexP = startIndexP == -1 ? -1 : query.subString(startIndexP).indexOf(')');
                    if(startIndexP != -1 && endIndexP != -1){
                        // map subquery fields, this needs to account for plural naming
                        // mapFields(query.substring(startIndexP, startIndexP + endIndexP + 1).split('\\s+'));
                        // remove subquery from main query
                        query = query.substring(0, startIndexP) + query.substring(startIndexP + endIndexP + 1);
                    }
					
                    
                    // map fields of main query
                    mapFields(query.split('\\s+'));
    
                }
                
                currentString = currentString.substring(endIndex + 1);
                startIndex = currentString.indexOf('[');
                endIndex = currentString.indexOf(']');
            }
    }
    
    @TestVisible
    private static void mapFields(List<String> queryList){
        // find SELECT and FROM keyword index
        Integer selectIndex = -1;
        Integer fromIndex = -1;
        for(Integer i = 0; i < queryList.size(); i++){
            if(queryList[i].replace('[','') == 'select' || queryList[i].replace('(','') == 'select'){
                selectIndex = i;
            } else if(queryList[i] == 'from'){
                fromIndex = i;
                queryList[fromIndex + 1] = queryList[fromIndex + 1].replace(']','').replace(')','');
            }
        }
        
        // map fields and count usage amounts to sObjects keys 
        Map<String, Integer> fields;
        if(allQueriedFields.containsKey(queryList[fromIndex + 1])){
            fields = allQueriedFields.get(queryList[fromIndex + 1]);
        }
        if(fields == null){
            fields = new Map<String, Integer>();
        }
        for(Integer i = selectIndex + 1; i < fromIndex; i++){
            // skip aggregate keywords
            if(AGGREGATE_KEYWORDS.contains(queryList[i])) {
                continue;
            }
            
            if(queryList[i].indexOf('.') != -1){
                // check lookup fields
                List<String> lookup = queryList[i].split('\\.');
                Map<String, Integer> lookupFields;
                if(allQueriedFields.containsKey(lookup[0])){
                    lookupFields = allQueriedFields.get(lookup[0]);
                }
                if(lookupFields == null){
                    lookupFields = new Map<String, Integer>();
                }
                //increment count or add as first
                lookupFields.put(lookup[1], lookupFields.containsKey(lookup[1]) ? lookupFields.get(lookup[1]) + 1 : 1);
                
        		// only add if fields are queried
                if(allQueriedFields.size() > 0) {
                    allQueriedFields.put(lookup[0], lookupFields);
                }
            } else {
                // increment count or add as first
                fields.put(queryList[i], fields.containsKey(queryList[i]) ? fields.get(queryList[i]) + 1 : 1);
            }
            
        }
        
        // only add if fields are queried
        if(fields.size() > 0) {
             allQueriedFields.put(queryList[fromIndex + 1], fields);
        }
    }
    
    @TestVisible
    private static void removeComments(){
        Integer startComment = -1;
        Integer endComment = -1;
        // remove multiline comments
        while (true){
            startComment = currentString.indexOf('/*');
            if(startComment == -1) { 
                break;
            }
            endComment = currentString.substring(startComment).indexOf('*/');
            if(endComment == -1) { 
                break;
            }
            currentString = currentString.substring(0, startComment) + currentString.substring(startComment + endComment + 4);
        }
        // remove single line comments
        while (true){
            startComment = currentString.indexOf('//');
            if(startComment == -1) {
                break;
            }
            endComment = currentString.substring(startComment).indexOf('\n');
            if(endComment == -1) {
                break;
            }
            currentString = currentString.substring(0, startComment) + currentString.substring(startComment + endComment + 1);
        }

    }

    public class FieldUsageScannerPayload {
        
        @AuraEnabled public Map<String, Map<String, Integer>> fields {get; set;}
        @AuraEnabled public Map<String, Map<ID, List<String>>> records {get; set;}

        public FieldUsageScannerPayload(){
            fields = allQueriedFields;
            records = recordsWithEmptyFields;
        }
    }
    
}