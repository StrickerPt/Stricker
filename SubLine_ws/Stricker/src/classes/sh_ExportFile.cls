global class sh_ExportFile implements Schedulable{
    public List<String> idOpps {get;set;}
    public List<Request> requests {get;set;}
    public Boolean sendVersion{get;set;}
    
    public sh_ExportFile(List<String> idOpps){
        this.idOpps = idOpps;
        this.sendVersion = false;
    }
    
    public sh_ExportFile(List<Request> requests){
        this.requests = requests;
        this.sendVersion = true;
    }
    
    global void execute(SchedulableContext SC) {
        if(!this.sendVersion){exportJob(idOpps);
        }else{
            exportVersion(requests);
        }
    }
    
    public static void exportVersion(List<Request> requests){
        List<Request> requestsRest = new List<Request>();
        Integer numCallout = 0;
        for(Request r :requests){                    
            numCallout ++;
            if(numCallout < 100 && r.contentSize < 5500000){Boolean result = Integrator.servico.gravarFicheiro(r.codigoDossier, r.apiCodigo, r.ano, r.fileBase64, r.ext);System.debug(result);
            }else{
                requestsRest.add(r);
            }
        }
        
        if(numCallout >= 100 && !requestsRest.isEmpty()){
            DateTime now  = DateTime.now();String nowToString = String.ValueOf(now);DateTime nextRunTime = now.addMinutes(2);
            String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
            sh_ExportFile sc = new sh_ExportFile(requestsRest);System.schedule('Reagendamento - sh_ExportFile '+nowToString, cronString, sc);
        }
    }
    
    @future (callout=true)
    public static void exportJob(List<String> idOpps){
        Set<String> oppsRunning = new Set<String>();
        List<String> oppsRest = new List<String>();
        Integer i = 1;
        for(String o: idOpps){
            if(i <= 100){
                oppsRunning.add(o);
            }else{
                oppsRest.add(o);
            }
            i++;
        }
        
        if(!oppsRunning.isEmpty()){
            runnigExport(oppsRunning);
        }
        
        if(idOpps.size() > 100){
            DateTime now  = DateTime.now();String nowToString = String.ValueOf(now);DateTime nextRunTime = now.addMinutes(2);
            String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
            sh_ExportFile sc = new sh_ExportFile(oppsRest);System.schedule('Reagendamento - sh_ExportFile '+nowToString, cronString, sc);
        }
    }
    
    public static void runnigExport(Set<String> oppsRunning){
        Schema.DescribeFieldResult fieldResult = Opportunity.Codigo_de_dossier__c.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        Map<String,PicklistValue> apiNames = new Map<String,PicklistValue>();
        for(Schema.PicklistEntry v : values) {
            PicklistValue plv = new PicklistValue();
            plv.value = v.getLabel();
            plv.apiName = v.getValue();
            apiNames.put(v.getValue(), plv);
        }
        Map<ID, Opportunity> opps = new Map<ID, Opportunity>([select Id,Auto_Number__c,Codigo_de_dossier__c,CreatedDate, Referencia_PHC__c from Opportunity where Id IN :oppsRunning]);
        Map<String,ID> contentIds = new Map<String,ID>();
        Map<String,List<ContentVersion>> m_Versions = new Map<String,List<ContentVersion>>();
        for(ContentDocumentLink ctl :[select LinkedEntityId,ContentDocumentId from ContentDocumentLink where LinkedEntityId IN :oppsRunning]){
            contentIds.put(ctl.ContentDocumentId,ctl.LinkedEntityId);
        }
        for(ContentVersion cv :[select Id,ContentDocumentId,VersionData, ContentSize,Title,FileExtension from ContentVersion where ContentDocumentId IN:contentIds.keySet()]){
            ID idOpp = contentIds.get(cv.ContentDocumentId);
            if(m_Versions.containsKey(IdOpp)){
                m_Versions.get(IdOpp).add(cv);
            }else{
                List<ContentVersion> auxVersions = new List<ContentVersion>();
                auxVersions.add(cv);m_Versions.put(IdOpp, auxVersions);
            }
        }
        Integer numCallout = 0;
        List<Request> requests = new List<Request>();
        for(String idOpp :m_Versions.keySet()){
            List<ContentVersion> auxVersions = m_Versions.get(idOpp);
            Opportunity opp = opps.get(idOpp);
            if(opp.Codigo_de_dossier__c != null){
                PicklistValue plv = apiNames.get(opp.Codigo_de_dossier__c);
                for(ContentVersion cv :auxVersions){
                    if(cv.ContentSize < 5500000){
                        numCallout ++;
                        if(numCallout <= 100){
                            String dossRef = opp.Referencia_PHC__c != null ? opp.Referencia_PHC__c : (opp.Auto_Number__c.contains('-') ? opp.Auto_Number__c.split('-')[1] : opp.Auto_Number__c);
                                Boolean result = false;
                            
                                result = doRequest(plv.value,
                                                   dossRef, 
                                                   String.valueOf(opp.CreatedDate.year()), 
                                                   EncodingUtil.base64Encode(cv.VersionData), 
                                                   (cv.Title.contains('.' + cv.FileExtension) ? cv.Title : cv.Title + '.' + cv.FileExtension));//2018-01-31 porque precisavam de extensão no ficheiro
                            
                            system.debug(result);
                        }else{
                            Request r = new Request();r.codigoDossier = plv.value;r.apiCodigo = plv.apiName;r.ano = String.valueOf(opp.CreatedDate.year());
                            r.fileBase64 = EncodingUtil.base64Encode(cv.VersionData);r.ext = (cv.Title.contains('.' + cv.FileExtension) ? cv.Title : cv.Title + '.' + cv.FileExtension);r.contentSize = cv.ContentSize;requests.add(r);
                        }
                    }
                }
            }
        }
        
        if(numCallout >= 100 && !requests.isEmpty()){
            DateTime now  = DateTime.now();String nowToString = String.ValueOf(now);DateTime nextRunTime = now.addMinutes(2);
            String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
            sh_ExportFile sc = new sh_ExportFile(requests);System.schedule('Reagendamento - sh_ExportFile '+nowToString, cronString, sc);
        }
    }
    public static String errorMsg = '';
    public static boolean doRequest(String siglaDossier,String numeroDossier,String anoDossier,String ficheiroBase64,String ext){
        boolean result  = false;
        try{
            result = Integrator.servico.gravarFicheiro(siglaDossier, numeroDossier, anoDossier, ficheiroBase64, ext);
            system.debug(LoggingLevel.INFO, result);
        }catch(Exception ex){
            errorMsg += result + ': ' +ex.getMessage() + '\r\n';
        }
        try{
            if(Limits.getCallouts() == Limits.getLimitCallouts()) throw new CalloutException('Esgotou tentativas de callouts: ' + Limits.getCallouts());
            if(!result) doRequest(siglaDossier, numeroDossier, anoDossier, ficheiroBase64, ext);
        }catch(CalloutException ex){
            String body = 'Ficheiros do dossier: ' + numeroDossier + ' não foram enviados. Excepção final: ' +  ex.getMessage() + ';\r\n'
                + errorMsg;
            UtilClaims.sendEmailFailure('Falha de exportação de ficheiro', body);
        }catch(Exception ex){
            String body = 'Ficheiros do dossier: ' + numeroDossier + ' não foram enviados. Excepção final: ' +  ex.getMessage() + ';\r\n'
                + errorMsg;
            UtilClaims.sendEmailFailure('Falha de exportação de ficheiro', body);
        }
        return true;
    }
    
    public class Request{
        public String codigoDossier{get;set;}
        public String apiCodigo{get;set;}
        public String ano{get;set;}
        public String fileBase64{get;set;}
        public String ext{get;set;}
        public Integer contentSize {get;set;}
    }
    
    class PicklistValue{
        public String apiName{get;set;}
        public String value{get;set;}
    }
}