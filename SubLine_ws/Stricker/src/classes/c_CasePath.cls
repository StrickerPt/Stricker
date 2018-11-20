public class c_CasePath {
    public String caseId {get;set;}
    public c_CasePath(){
        
    }
    
    public List<Stage> getStages(){ 
        Case caso = [select id, Status, IsClosed From Case Where Id = :caseId];
        boolean foundStage = true;
        Schema.sObjectType sobject_typec = Case.getSObjectType();
        Schema.DescribeSObjectResult sobject_describec = sobject_typec.getDescribe();
        Map<String, Schema.SObjectField> field_mapc = sobject_describec.fields.getMap();
        List<Schema.PicklistEntry> pick_list_valuesc = field_mapc.get('Status').getDescribe().getPickListValues();
        
        List<Stage> retList = new List<Stage>();
        Integer index = 0;
        for (Schema.PicklistEntry a : pick_list_valuesc) {
            if(caso.Status == a.getValue()){
                foundStage = false;
            }
            
            boolean isComplete = caso.Status != a.getValue() && (foundStage || caso.IsClosed);
            boolean isCurrent = caso.Status == a.getValue();
            Stage newStg = new Stage(isComplete, isCurrent, a.getLabel(), index);
            retList.add(newStg);
            index++;
        }
        retList.sort();
        return retList;
    }
    
    public class Stage implements Comparable{
        public boolean isComplete {get;set;}
        public boolean isCurrent {get;set;}
        public String label {get;set;}
        public Integer index {get;set;}
        
        public Stage(boolean isComplete, boolean isCurrent, String label,Integer index){
            
            this.isComplete = isComplete;
            this.isCurrent = isCurrent;
            this.label = label;
            this.index = index;
        }
        
        
        public Integer compareTo(Object compareTo) {
            Stage compareToCust = (Stage)compareTo;
            Integer returnValue = 0;
            
            if(this.index > compareToCust.index){
                returnValue = 1;       
            }else if(this.index < compareToCust.index){
                returnValue = -1;   
            }
            return returnValue;
        }
    }
}