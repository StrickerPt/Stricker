//31.08.2017***
//CB no dossier criado da web
//usar webservice para ir buscar o link do documento da Web
//*************
global class b_getWebDocument implements Schedulable{ 
    public String NWeb {get;set;}
    
    public b_getWebDocument(){
        this.NWeb = '';
    }
    public b_getWebDocument(String NWeb){
        this.NWeb = NWeb;
    }
    
    global void execute(SchedulableContext SC) {
        futureJob(NWeb);
    }
    
    @future(callout=true)
    public static void futureJob(String NWeb){
        
        Integer limitCallout = 1;
        
        List<clientStrickerSite.ArrayOfViewerFichEncomenda> results = new List<clientStrickerSite.ArrayOfViewerFichEncomenda>();
        do{         
            clientStrickerSite.ArrayOfViewerFichEncomenda result = new clientStrickerSite.sitePStrickerSalesSoap().lstFicheirosByEncomenda(NWeb); //IntegratorSite.consultaWebDocument(NWeb);
            
            limitCallout++;
            
            results.add(result);
            
        }while(limitCallout <= 1);
        
        if(!results.isEmpty()){
            
            List<String> sId_NWEB = new List<String>();
            
            for(clientStrickerSite.ArrayOfViewerFichEncomenda res: results){
                for(clientStrickerSite.viewerFichEncomenda r : res.viewerFichEncomenda){
                    sId_NWEB.add(r.idEncomenda);
                }
            }                        
                     
			List<Opportunity> newOpps = new List<Opportunity>();
            Map<Id, Opportunity> map_Opp = new Map<Id, Opportunity>();
            List<Opportunity> m_Opp = [Select id,NWEB__c from Opportunity where NWEB__c IN: sid_NWEB];
            for(Opportunity o: m_opp){
                map_Opp.put(o.Id, o);
            }
            for(clientStrickerSite.ArrayOfViewerFichEncomenda res: results){
                for(clientStrickerSite.viewerFichEncomenda r : res.viewerFichEncomenda){
                    Opportunity new_opp = new Opportunity();
                    new_opp.Id = map_opp.get(r.idEncomenda).id;
                    new_opp.URL_Documento_Web__c = r.URLCompleto;
                    newOpps.add(new_opp); 
                }
            } 
            
            if(!newOpps.isEmpty()) upsert newOpps;
        }
        /*
        if(limitCallout >= 1){
            DateTime now  = DateTime.now();
            String nowToString = String.ValueOf(now);
            DateTime nextRunTime = now.addMinutes(1);
            String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
            
            
            b_getWebDocument sc = new b_getWebDocument(NWEB);
            System.schedule('Reagendamento - b_getWebDocument '+nowToString, cronString, sc);
        }
        */
    }
            
   
}