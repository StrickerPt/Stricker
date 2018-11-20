public class c_WebDocument{  
    
    public PageReference pgReturnPage;
    Public string IdUrl {get;set;} 
    public boolean sucess {get;set;}
    public c_WebDocument(ApexPages.StandardController stdController){  
        IdUrl  = stdController.GetID();
        sucess = true;
        string stesteUrl = ApexPages.currentPage().getParameters().get('retUrl');
        
        String returnUrl = '/' + stesteUrl;
        pgReturnPage = new PageReference(returnUrl);
        pgReturnPage.setRedirect(true);
        
    }
    
    public PageReference RedirectOpp(){

        Opportunity opp = [SELECT id,Nweb__c,URL_Documento_Web__c FROM Opportunity WHERE id =:IdUrl];     
        boolean hasDocs = false;
        String openWindows = 'javascript:';
        if(opp.Nweb__c != null){
            //List<c_ViewerWebDocument.ViewerWebDocument> linhas = new List<c_ViewerWebDocument.ViewerWebDocument>();
            clientStrickerSite.ArrayOfViewerFichEncomenda result = new clientStrickerSite.sitePStrickerSalesSoap().lstFicheirosByEncomenda(opp.Nweb__c);  
            if(result.viewerFichEncomenda != null){
                for(clientStrickerSite.viewerFichEncomenda viewerLog : result.viewerFichEncomenda){
                    openWindows += 'openFile("' + viewerLog.URLCompleto + '");';
                    hasDocs = true;
                    opp.URL_Documento_Web__c = viewerLog.URLCompleto;
                    update opp;
                }
            }
            /*string sUrl = null;    
            if(WebDocument != null){
            return new  PageReference ('/006/e?retURL={!Oportunidade__r.Id}');
            }else{
            return pgReturnPage;
            }*/
            //string url = 'https://www.stricker-europe.com/fotos/encomendas/customizador/1664_logo_vectorizado_88565361959a7d3088cb19.jpg';
            
        }
        
        if(opp.URL_Documento_Web__c != null || hasDocs){
            openWindows += 'openPrimaryTabConsole();';
            PageReference page = new PageReference(openWindows);
            page.setRedirect(true);
            
            return page ;
        }

        sucess = false;
        return null;
        
    }  
}