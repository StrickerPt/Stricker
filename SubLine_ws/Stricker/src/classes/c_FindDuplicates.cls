public class c_FindDuplicates {
    public ApexPages.StandardController stdCtrl;
    
    public List<Lead> leads {get;set;}
    public List<Schema.FieldSetMember> fields {get;set;}
    public Lead finalLead {get;set;}
    public String fieldToChange {get;set;}
    public String leadValue {get;set;}
    public boolean isSucess {get;set;}
    
    public boolean existsNewRecord {get;set;}
    
    public Map<Id, Lead> auxLeadMap;
    public Set<String> lockedField {get;set;}
    
    public List<MergeLead> mergeLeads {get;set;}//leads mostradas no modal para selecção 
    public Lead mergedLead {get;set;}
    
    public c_FindDuplicates(ApexPages.StandardController stdCtrl){
        /****VARIAVEIS***/
        this.stdCtrl = stdCtrl;
        List<String> newFields = new List<String>{'RecordType.Name', 'Name'};
        Id leadID = stdCtrl.getId();
        existsNewRecord = false;
        leads = new List<Lead>();
        String whereClause = '';
        boolean isFirst = true;
        mergeLeads = new List<MergeLead>();
        isSucess = false;
        
        /****CAMPOS PARA LEAD ORIGINAL E ESTRUTURA DE CAMPOS TRANCADOS***/
        lockedField = new Set<String>();
        for(Schema.FieldSetMember fs : SObjectType.Lead.FieldSets.Locked_Fields.getFields()){
            lockedField.add(fs.getFieldPath());
            newFields.add(fs.getFieldPath());
        }
        
        List<MatchingRule> rules = [Select id, (Select id, MatchingMethod, Field From MatchingRuleItems) From MatchingRule Where SobjectType = 'Lead' And RuleStatus = 'Active'];
        
        
        for(MatchingRule rule: rules){
            for(MatchingRuleItem item :rule.MatchingRuleItems){
                newFields.add(item.Field);
            }
        }
        
        if(!Test.isRunningTest()){
        	stdCtrl.addFields(newFields);
        }
        finalLead = (Lead) stdCtrl.getRecord();
        
        /****CONSTRUÇÃO DA WHERE CLAUSE***/
        for(MatchingRule rule: rules){
            for(MatchingRuleItem item :rule.MatchingRuleItems){
                try{
                    if(stdCtrl.getRecord().get(item.Field) != null){
                        if(isFirst){
                            isFirst = false;
                            whereClause += '( ';
                        }else{
                            whereClause += ' Or ';
                        }
                        if(item.MatchingMethod == 'Exact'){
                            whereClause += item.Field + ' = ' + ' \'' + stdCtrl.getRecord().get(item.Field) + ' \'';
                        }else{
                            whereClause += item.Field + ' Like ' + ' \'%' + stdCtrl.getRecord().get(item.Field) + '%\'';
                        }
                    }
                }catch(Exception ex){}
            }
        }
        if(whereClause != '') whereClause += ')';
        
        fields = objectQueryFields('Lead');// lista de todos os campos
        
        string queryFinalLead = 'SELECT '+queryBuilder('Lead') + ', RecordType.Name, Name' ;
        queryFinalLead += ' FROM Lead Where Id = \'' + finalLead.Id + '\' And isConverted = false';
        
        finalLead = ((List<Lead>)Database.query(queryFinalLead)).get(0);
        leads.add(finalLead);//garante que a lead original está em primeiro lugar
        
        string queryC = 'SELECT '+queryBuilder('Lead') + ', RecordType.Name, Name' ;
        queryC += ' FROM Lead Where Id != \'' + finalLead.Id + '\' And isConverted = false ';
        queryC += (whereClause != '' ? ' And ' + whereClause : '');

        system.debug(queryC);
        
        leads.addAll((List<Lead>)Database.query(queryC));
        auxLeadMap = new  Map<Id, Lead>();
        
        //
        for(Lead lead : leads){
            auxLeadMap.put(lead.Id, lead);
            if(lead.RecordType.Name == 'Novo registo site'){
                existsNewRecord = true;
                if(finalLead.RecordType.Name != 'Novo registo site'){
                    for(String lf : lockedField){
                        finalLead.put(lf, lead.get(lf));
                    }
                }
            }
            
            mergeLeads.add(new MergeLead(lead.Id == finalLead.Id ? true : false, lead));
        }
    }
    
    public String getLockedFields(){
        string result = ''; 
        for(String s : lockedField){
            result += s + ';';   
        }
        return result;
    }
    
    public void assignValue(){
        if(fieldToChange!= null && leadValue != null){
            if(auxLeadMap.containsKey(leadValue)){
                try{
                    finalLead.put(fieldToChange, auxLeadMap.get(leadValue).get(fieldToChange));
                }catch(Exception ex){}
            }
        }
        system.debug(finalLead);
    }
    
    public static String queryBuilder(String objectName){
        
        String query = '';
        
        Boolean isFirst = true;
        
        for(Schema.FieldSetMember field : objectQueryFields(objectName)){
            if(isFirst){
                query += field.getFieldPath();
                isFirst = false;
            }else{
                query += ' ,'+field.getFieldPath();
            }
        }
        
        return query;
    }
    
    public static List<Schema.FieldSetMember> objectQueryFields(String objectName){
        
        List<Schema.FieldSetMember> queryFields = new List<Schema.FieldSetMember>();
        
        if(objectName == 'Lead'){
            queryFields.addAll(SObjectType.Lead.FieldSets.Locked_Fields.getFields());
            queryFields.addAll(SObjectType.Lead.FieldSets.Merge_Fields.getFields());
        }
        
        return queryFields;
    }
    
    public void mergeLeads(){
        try{
            
            update finalLead;
            List<Lead> deleteLeads = new List<Lead>();
            for(MergeLead lead : mergeLeads){
                if(lead.selected && lead.lead.Id != finalLead.Id)
                    deleteLeads.add(lead.lead);
            }
            if(!deleteLeads.isEmpty()) delete deleteLeads;
            isSucess = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,''));
        }catch(Exception ex){
            
        }
    }
    
    public class MergeLead{
        public boolean selected {get;set;}
        public Lead lead {get;set;}
        
        public MergeLead(boolean selected, Lead lead){
            this.selected = selected;
            this.lead = lead;
        }
    }
}