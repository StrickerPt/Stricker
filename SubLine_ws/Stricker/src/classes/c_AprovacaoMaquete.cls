public class c_AprovacaoMaquete {
    public Id idOpp{get;set;}
    public Opportunity opp {get;set;}
    
    public OpportunityLineItem getProdName(){
        List<OpportunityLineItem> auxOli = new List<OpportunityLineItem>();
        if(this.idOpp != null){
            auxOli = [select Lingua_do_cliente_idioma__c from OpportunityLineItem where OpportunityId = :idOpp and Product2.RecordType.Name = 'Produto'];
        }
        if(!auxOli.isEmpty()){
            return auxOli[0];}return null;
        
    }
    
    public Opportunity getComercial(){
        Opportunity opp = new Opportunity();
        if(this.idOpp != null){
            opp = [select Owner.Assinatura_email__c,Owner.Name, Referencia_Interna__c, Auto_number__c,Referencia_PHC__c, Versao_de_maquete_enviada__c from Opportunity where Id = :idOpp];
            return opp;}return null;
    }
    
    public ContentVersion getMaquete(){
        if(this.idOpp != null){
            List<ContentDocumentLink> cdl = [SELECT ContentDocument.Id FROM ContentDocumentLink WHERE ContentDocument.title like 'FO%' AND LinkedEntityId = :idOpp limit 1];
            if(cdl != null && !cdl.isEmpty()){
                List<ContentVersion> cv = [SELECT Id,VersionNumber,Title FROM ContentVersion where ContentDocumentId =:cdl[0].ContentDocument.Id and IsLatest = true];
                if(cv != null && !cv.isEmpty()){
                    return cv[0];
                }
            }
        }
        return null;
    }
    
    public static String getLogoUrl(){
        List<Document> lstDocument = [Select Id,Name,LastModifiedById from Document where DeveloperName = 'Logo' limit 1];
        string instancia = URL.getSalesforceBaseUrl().getHost().substring(0, URL.getSalesforceBaseUrl().getHost().indexOf('.'));
        if(instancia == 'c') instancia = 'cs88';
        else if(instancia == 'e') instancia = 'eu11';
        if(!lstDocument.isEmpty()){string strDocUrl = URL.getSalesforceBaseUrl().getProtocol() + '://c.' + instancia + '.content.force.com'+ '/servlet/servlet.ImageServer?id=' + lstDocument[0].Id + '&oid=' + UserInfo.getOrganizationId();return strDocUrl;
        }
        return '';
    }
    
    public static String getSiteURL(){
        String url = [Select id, Url__c From Site_Url__mdt Where QualifiedApiName = 'Site_Url'].Url__c;
        return url;
    }
}