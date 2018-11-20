public class c_MaquetesPipeline {
    public List<Opportunity> fosList {get;set;}
    public List<Opportunity> foisList {get;set;}
    public List<Opportunity> tudoList {get;set;}
    public List<GeralTable> geralList {get;set;}
    public Map<Id, Long> mapHours {get;set;}
    public Datetime meanDate {get;set;}
    public Integer meanHours {get;set;}
    public Integer meanMinutes {get;set;}
    public Id report1Id {get;set;}
    public Integer nMaqsTotal {get;set;}
    public DesignerChartConfig__c manometro {get;set;}
    public List<Opportunity> showList {get;set;}
    public c_MaquetesPipeline(){
        manometro = DesignerChartConfig__c.getValues('Manometro');
        BusinessHours bh = [SELECT Id, Name, IsActive, IsDefault, SundayStartTime, SundayEndTime, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime, WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, 
                            ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime, TimeZoneSidKey, SystemModstamp, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, LastViewedDate 
                            FROM BusinessHours Where Name = 'PT'];
        fosList = new List<Opportunity>();
        foisList = new List<Opportunity>();
        tudoList = new List<Opportunity>();
        showList = new List<Opportunity>();

        mapHours = new Map<Id, Long>();
        
        for(Opportunity opp : [select id,Auto_Number__c,Account.BillingCountryCode,Account.Name,data_limite_de_maquete__c,Data_do_pedido_de_maquete__c,Estado_da_maquete__c,
                   Designer__c, Referencia_PHC__c,RecordType.DeveloperName,Auxiliar_retificacao__c,Maquete_em_pausa__c,Snapshot_de_maquete__c,Maquete_em_atraso__c
                   ,Snapshot_em_atraso__c 
                   from opportunity 
                   where data_limite_de_maquete__c != null
                   And (RecordType.DeveloperName = 'Folha_de_Obra' Or RecordType.DeveloperName = 'Folha_de_Obra_de_Importacao')
                   //Filtro retirado a 21-12-2017 por possiveis incoerencias dos dados
                   //And Account.BillingCountryCode != null
                   And Data_de_envio_de_maquete__c = null
                   ORDER BY Data_do_pedido_de_maquete__c ASC]){
                       if(opp.RecordType.DeveloperName == 'Folha_de_Obra'){
                           fosList.add(opp);
                       }else if(opp.RecordType.DeveloperName == 'Folha_de_Obra_de_Importacao'){
                           foisList.add(opp);
                       }
                       tudoList.add(opp);

                       //calculateHours
                       mapHours.put(opp.Id, (BusinessHours.diff(bh.Id, System.now(), opp.Data_limite_de_maquete__c)/1000/60));
        }
        geralList = new List<GeralTable>();
        GeralTable pipeline = new GeralTable('Pipeline');
        GeralTable entregues = new GeralTable('Entregues');
        GeralTable incompletas = new GeralTable('Incompletas');
        Long meanTime = 0;
        Integer nEntregues = 0;
        nMaqsTotal = 0;
        for(Opportunity opp : [select id,Auto_Number__c,Account.BillingCountryCode,Account.Name,data_limite_de_maquete__c,Data_do_pedido_de_maquete__c,
            Estado_da_maquete__c,Designer__c, Referencia_PHC__c,Data_limite_de_producao__c,Data_de_envio_de_maquete__c,Auxiliar_retificacao__c,
            Maquete_em_pausa__c,Snapshot_de_maquete__c,Maquete_em_atraso__c,Snapshot_em_atraso__c,
            (Select id,Data_de_envio__c,Em_atraso__c,Tipo__c, CreatedDate,Destinatario__c From Pedidos_de_Maquete__r Where CreatedDate > :System.today())
            from opportunity 
            where data_limite_de_maquete__c != null
            And (RecordType.DeveloperName = 'Folha_de_Obra' OR RecordType.DeveloperName = 'Folha_de_Obra_de_Importacao')
            //And Account.BillingCountryCode != null
            And (data_limite_de_maquete__c > :System.today() OR (Data_do_pedido_de_maquete__c != null And Data_de_envio_de_maquete__c = null) 
                OR Data_de_envio_de_maquete__c > :System.today())
            ORDER BY Data_do_pedido_de_maquete__c ASC]){
                for(Pedido_de_Maquete__c pedido : opp.Pedidos_de_Maquete__r){
                    if(pedido.Data_de_envio__c == null){//está em pipeline
                        //if((opp.data_limite_de_maquete__c < system.now() && opp.Estado_da_maquete__c != 'Pendente') 
                        //|| (opp.Estado_da_maquete__c == 'Pendente' && opp.Snapshot_em_atraso__c)){
                        //Quando a maquete estava pendente o tempo parava de contar
                        if(opp.data_limite_de_maquete__c < system.now()){//está em atraso
                            if(pedido.Tipo__c == 'Retificação'){//retificação
                                pipeline.ret += 1;
                                pipeline.atraso.ret += 1;
                            }else{//original
                                pipeline.current += 1;
                                pipeline.atraso.current += 1;
                            }
                        }else{//em dia
                            if(pedido.Tipo__c == 'Retificação'){//retificação
                                pipeline.ret += 1;
                                pipeline.dia.ret += 1;
                            }else{//original
                                pipeline.current += 1;
                                pipeline.dia.current += 1;
                            }
                        }
                    }else{//já foi entregue
                        if(pedido.Em_atraso__c){
                            if(pedido.Tipo__c == 'Retificação'){
                                entregues.ret += 1;
                                entregues.atraso.ret += 1;
                                if(pedido.Destinatario__c == 'Comercial'){
                                    incompletas.ret += 1;
                                    incompletas.atraso.ret += 1;
                                }
                            }else{
                                entregues.current += 1;
                                entregues.atraso.current += 1;
                                if(pedido.Destinatario__c == 'Comercial'){
                                    incompletas.current += 1;
                                    incompletas.atraso.current += 1;
                                }
                            }
                        }else{
                            if(pedido.Tipo__c == 'Retificação'){
                                entregues.ret += 1;
                                entregues.dia.ret += 1;
                                if(pedido.Destinatario__c == 'Comercial'){
                                    incompletas.ret += 1;
                                    incompletas.dia.ret += 1;
                                }
                            }else{
                                entregues.current += 1;
                                entregues.dia.current += 1;
                                if(pedido.Destinatario__c == 'Comercial'){
                                    incompletas.current += 1;
                                    incompletas.dia.current += 1;
                                }
                            }
                        }
                        meanTime += BusinessHours.diff(bh.Id,pedido.CreatedDate ,pedido.Data_de_envio__c)/1000/60;
                        system.debug(meanTime);
                        nEntregues++;
                    }
                }
                //Se o pedido não for de hoje
                if(opp.Pedidos_de_Maquete__r.isEmpty()){
                    if(opp.Data_de_envio_de_maquete__c == null){//está em pipeline
                        // && opp.Estado_da_maquete__c != 'Pendente') 
                        // || (opp.Estado_da_maquete__c == 'Pendente' && opp.Snapshot_em_atraso__c)
                        // Quando a maquete estava pendente o tempo parava de contar
                        if(opp.data_limite_de_maquete__c < system.now()){//está em atraso
                               if(opp.Auxiliar_retificacao__c){//retificação
                                   pipeline.ret += 1;
                                   pipeline.atraso.ret += 1;
                               }else{//original
                                   pipeline.current += 1;
                                   pipeline.atraso.current += 1;
                               }
                           }else{//em dia
                               if(opp.Auxiliar_retificacao__c){//retificação
                                   pipeline.ret += 1;
                                   pipeline.dia.ret += 1;
                               }else{//original
                                   pipeline.current += 1;
                                   pipeline.dia.current += 1;
                               }
                           }
                    }else{//já foi entregue
                        if(opp.data_limite_de_maquete__c < opp.Data_de_envio_de_maquete__c){
                            if(opp.Auxiliar_retificacao__c){
                                entregues.ret += 1;
                                entregues.atraso.ret += 1;
                                if(opp.Estado_da_maquete__c == 'Pendente'){
                                    incompletas.ret += 1;
                                    incompletas.atraso.ret += 1;
                                }
                            }else{
                                entregues.current += 1;
                                entregues.atraso.current += 1;
                                if(opp.Estado_da_maquete__c == 'Pendente'){
                                    incompletas.current += 1;
                                    incompletas.atraso.current += 1;
                                }
                            }
                        }else{
                            if(opp.Auxiliar_retificacao__c){
                                entregues.ret += 1;
                                entregues.dia.ret += 1;
                                if(opp.Estado_da_maquete__c == 'Pendente'){
                                    incompletas.ret += 1;
                                    incompletas.dia.ret += 1;
                                }
                            }else{
                                entregues.current += 1;
                                entregues.dia.current += 1;
                                if(opp.Estado_da_maquete__c == 'Pendente'){
                                    incompletas.current += 1;
                                    incompletas.dia.current += 1;
                                }
                            }
                        }
                        meanTime += BusinessHours.diff(bh.Id,opp.Data_do_pedido_de_maquete__c ,opp.Data_de_envio_de_maquete__c)/1000/60;
                        nEntregues++;
                    }
                }
                
            }
        
        List<Report> reps = [Select id From Report Where Name = 'Designer - Estado da maquete'];
        if(!reps.isEmpty()) report1Id = reps.get(0).Id;
        nMaqsTotal = nEntregues;
        meanTime /= (nEntregues != 0 ? nEntregues : 1) ;
        meanHours = (Integer) Math.floor(Decimal.valueOf(meanTime/60));
        system.debug(meanHours);
        meanMinutes = (Integer) Math.floor(Decimal.valueOf(meanTime - meanHours*60));
        system.debug(meanMinutes);
        geralList.add(pipeline);
        geralList.add(entregues);
        geralList.add(incompletas);
    }
    
    public static String getLogoUrl(){
        List<Document> lstDocument = [Select Id,Name,LastModifiedById from Document where DeveloperName = 'Logo' limit 1];
        if(!lstDocument.isEmpty()){string strOrgId = UserInfo.getOrganizationId();string orgInst = URL.getSalesforceBaseUrl().getHost();string strDocUrl = URL.getSalesforceBaseUrl().getProtocol() + '://' + orgInst + '/servlet/servlet.ImageServer?id=' + lstDocument[0].Id + '&oid=' + strOrgId;return strDocUrl;
        }
        return '';
    }
    
    public String param1 {get;set;}
    public String param2 {get;set;}
    public void buildShowList(){
        showList = new List<Opportunity>();
        String data = System.today().year() + '-' + (System.today().month() < 10 ? '0' :'') + System.today().month() + '-' + (System.today().day() < 10 ? '0': '') + System.today().day() + 'T00:00:00Z';
        String agora = System.now().year()
            + '-' + (System.now().month() < 10 ? '0' :'') + System.now().month()
            + '-' + (System.now().day() < 10 ? '0' :'') + System.now().day()
            + 'T' + (System.now().hour() < 10 ? '0' :'') + System.now().hour()
            + ':' + (System.now().minute() < 10 ? '0': '') + System.now().minute()
            + ':' + (System.now().second() < 10 ? '0': '') + System.now().second()
            + 'Z';
        system.debug(agora);
        String query = 'select id,Auto_Number__c,Account.BillingCountryCode,Account.Name,data_limite_de_maquete__c,Data_do_pedido_de_maquete__c,'
            +'Estado_da_maquete__c,Designer__c, Referencia_PHC__c,Data_limite_de_producao__c,Data_de_envio_de_maquete__c,Auxiliar_retificacao__c,'
            +'Maquete_em_pausa__c,Snapshot_de_maquete__c,Maquete_em_atraso__c,Snapshot_em_atraso__c'
            +' from opportunity '
            +' where data_limite_de_maquete__c != null'
            +' And (RecordType.DeveloperName = \'Folha_de_Obra\' OR RecordType.DeveloperName = \'Folha_de_Obra_de_Importacao\')'
            //+' And Account.BillingCountryCode != null'
            +' And Data_do_pedido_de_maquete__c != null';
        
        if(param1 == 'header'){
            if(param2 == 'Pipeline'){
                query += ' And Id In (Select Oportunidade__c From Pedido_de_Maquete__c Where Data_de_envio__c = null )';
                system.debug(query);
            }else if(param2 == 'Entregues'){
                query += ' And Id In (Select Oportunidade__c From Pedido_de_Maquete__c Where (CreatedDate > ' + data + 'OR Data_de_envio__c > '+ data +') And Data_de_envio__c != null)';
                system.debug(query);
            }else if(param2 == 'Incompletas'){
                query += ' And Id In (Select Oportunidade__c From Pedido_de_Maquete__c Where (CreatedDate > ' + data + 'OR Data_de_envio__c > '+ data +') And Data_de_envio__c != null And Destinatario__c = \'Comercial\')';
            }
        }else{
            if(param1 == 'Pipeline'){
                if(param2 == 'Em dia'){
                    query += ' And Id In (Select Oportunidade__c From Pedido_de_Maquete__c Where Data_de_envio__c = null '
                        + 'And Oportunidade__r.data_limite_de_maquete__c > ' + agora + ')';
                        // + 'And Oportunidade__r.Estado_da_Maquete__c != \'Pendente\') Or (Oportunidade__r.Estado_da_Maquete__c = \'Pendente\' And Oportunidade__r.Snapshot_em_Atraso__c = false)))';
                    showList = Database.query(query);
                }else if(param2 == 'Em atraso'){
                    query += ' And Id In (Select Oportunidade__c From Pedido_de_Maquete__c Where Data_de_envio__c = null'
                        +' And Oportunidade__r.data_limite_de_maquete__c < ' + agora + ')';
                        //+ ' And Oportunidade__r.Estado_da_Maquete__c != \'Pendente\') Or (Oportunidade__r.Estado_da_Maquete__c = \'Pendente\' And Oportunidade__r.Snapshot_em_Atraso__c = true)))';
                    showList = Database.query(query);
                }
            }else if(param1 == 'Entregues'){
                if(param2 == 'Em dia'){
                    query += ' And Id In (Select Oportunidade__c From Pedido_de_Maquete__c Where (CreatedDate > ' + data + 'OR Data_de_envio__c > '+ data +') And Data_de_envio__c != null And Em_atraso__c = false)';
                    showList = Database.query(query);
                }else if(param2 == 'Em atraso'){
                    query += ' And Id In (Select Oportunidade__c From Pedido_de_Maquete__c Where (CreatedDate > ' + data + ' OR Data_de_envio__c > '+ data +') And Data_de_envio__c != null And Em_atraso__c = true)';
                    showList = Database.query(query);
                }
            }else if(param1 == 'Incompletas'){
                if(param2 == 'Em dia'){
                    query += ' And Id In (Select Oportunidade__c From Pedido_de_Maquete__c Where (CreatedDate > ' + data + 'OR Data_de_envio__c > '+ data +') And Data_de_envio__c != null And Em_atraso__c = false And Destinatario__c = \'Comercial\')';
                    showList = Database.query(query);
                }else if(param2 == 'Em atraso'){
                    query += ' And Id In (Select Oportunidade__c From Pedido_de_Maquete__c Where (CreatedDate > ' + data + ' OR Data_de_envio__c > '+ data +') And Data_de_envio__c != null And Em_atraso__c = true And Destinatario__c = \'Comercial\')';
                    showList = Database.query(query);
                }
            }
        }
        query += ' ORDER BY Data_do_pedido_de_maquete__c ASC';
        showList = Database.query(query);
    }
    
    //*************************************ESTRUTURAS
    public class GeralTable{
        public String name {get;set;}
        public Integer current {get;set;}
        public Integer ret {get;set;}
        public GeralSubTable dia {get;set;}
        public GeralSubTable atraso {get;set;}
        
        public GeralTable(String name){
            this.name = name;
            current = 0;
            ret = 0;
            dia = new GeralSubTable('Em dia');
            atraso = new GeralSubTable('Em atraso');
        }
    }
    public class GeralSubTable{
        public String name {get;set;}
        public Integer current {get;set;}
        public Integer ret {get;set;}
        
        public GeralSubTable(String name){
            this.name = name;
            current = 0;
            ret = 0;
        }
    }
}