public class c_checkLeadVat{
    public displayInfo v_displayInfo {get;set;}
    public Lead lead {get;set;} 
    
    public c_checkLeadVat(ApexPages.StandardController controller){
        try{
            
            this.lead = [select id,Numero_de_contribuinte__c,Prefixo_de_contribuinte__c,Company,Pais_europeu__c, Isento_de_IVA__C From Lead where id = :controller.getId()];
            
            if(lead.Numero_de_contribuinte__c != null && lead.Prefixo_de_contribuinte__c != null && lead.Pais_europeu__c){
                checkVat.checkVatPort vatService = new checkVat.checkVatPort();
                checkVatTypes.checkVatResponse_element vatResponse = vatService.checkVat(lead.Prefixo_de_contribuinte__c, lead.Numero_de_contribuinte__c);
                
                v_displayInfo = new displayInfo(vatResponse.countryCode, vatResponse.vatNumber, vatResponse.requestDate, vatResponse.valid, vatResponse.name, vatResponse.address);
                
            }
        }catch(Exception ex){system.debug(ex.getMessage());}
    }
    
    public void copyName(){
        this.lead.Company = v_displayInfo.name;
        update this.lead;
    }
    
    public void checkIsento(){
        try{
            if(v_displayInfo.valid && !lead.Isento_de_IVA__C) marcaIsentoIVA(lead.Id);
        }catch(Exception ex){}
    }
    
    public class displayInfo{
        public String countryCode {get;set;}
        public String vatNumber {get;set;}
        public Date requestDate {get;set;}
        public Boolean valid {get;set;}
        public String name {get;set;}
        public String address {get;set;}
        
        public displayInfo(String countryCode, String vatNumber, Date requestDate,Boolean valid, String name, String address){
            this.countryCode = countryCode;
            this.vatNumber = vatNumber;
            this.requestDate = requestDate;
            this.valid = valid;
            this.name = name;
            this.address = address;
        }
    }
    
    @future
    public static void marcaIsentoIVA(Id idLead){
        try{
            Lead lead = new Lead(Id = idLead);
            lead.Isento_de_IVA__C = true;
            
            update lead;
        }catch(Exception ex){}
    }
}