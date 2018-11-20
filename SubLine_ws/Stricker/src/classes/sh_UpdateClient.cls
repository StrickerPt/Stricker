global class sh_UpdateClient implements Schedulable{
    public static String errorMessage = '';
    public Set<Id> idAccs {get;set;}
    
    public sh_UpdateClient(Set<Id> ids){
        this.idAccs = ids;
    }
    
    global void execute(SchedulableContext SC) {
        job(idAccs);
    }
    
    @future(callout=true)
    public static void job(Set<Id> ids){
        system.debug('Entraram ' + ids.size() + ' ids;');
        Set<Id> accsRunning = new Set<Id>();
        Set<Id> accsRest = new Set<Id>();
        Integer i = 1;
        for(Id s: ids){
            if(i <= 100){
                accsRunning.add(s);
            }else{
                accsRest.add(s);
            }
            i++;
        }
        
        system.debug('Vou correr ' + accsRunning.size() + ' ids;');
        //chama servico
        doWork(accsRunning);
        
        
        if(ids.size() > 100){
            DateTime now  = DateTime.now();
            String nowToString = String.ValueOf(now);
            DateTime nextRunTime = now.addMinutes(1);
            String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
            system.debug('Proximo batch: ' + accsRest.size() + ' ids;');
            sh_UpdateClient sc = new sh_UpdateClient(accsRest);
            System.schedule('Reagendamento - sh_UpdateClient '+nowToString, cronString, sc);
        }
    }
    
    public static void doWork(Set<Id> ids){
        checkRecursive.runAccount = false;
        
        String query = 'SELECT '+Integrator.queryBuilder('Account') + ',Assistente_comercial__r.Name,Diretor_comerial__r.Name,Owner.Name,Owner.Codigo_de_utilizador__c,CurrencyIsoCode';
        query += ' FROM Account WHERE id IN :ids';
        
        List<Account> listAccounts = Database.query(query);

        doRequests(listAccounts);
        
        if(!listAccounts.isEmpty()) update listAccounts;
        
    }
    
    public static void doRequests(List<Account> listAccounts){
        
        for(Account acc :listAccounts){
            //system.debug(acc);
            //CurrencyConverter.convert(acc.field, acc.CurrencyIsoCode, 'EUR')
            try{
                
                wsdl_Clientes.ClienteActSalesToPHC req = new wsdl_Clientes.ClienteActSalesToPHC();
                req.Numero_de_cliente_xc =acc.Numero_de_cliente__c;
                req.Bloqueado_xc = acc.Bloqueado__c;
                req.Inativo_xc = acc.Inativo__c;
                req.Encomendas_canceladas_xc = acc.Encomendas_canceladas__c;
                req.Email_xc = acc.Email__c != null ? acc.Email__c : '';
                req.Email_de_envio_de_documentos_xc = acc.Email_de_envio_de_documentos__c != null ? acc.Email_de_envio_de_documentos__c : '';
                req.Phone = acc.Phone != null ? acc.Phone : '';
                req.Website = acc.Website != null ? EncodingUtil.base64Encode(Blob.valueof(acc.website)) : '';
                req.Idioma_xc = acc.Idioma__c != null ? acc.Idioma__c : '';
                req.Idioma_para_documentos_xc = acc.Idioma_para_faturacao__c != null ? acc.Idioma_para_faturacao__c : '';
                req.BillingState = acc.Zona__c != null ? acc.Zona__c : '';
                req.Vendedor_xc =(String)acc.Codigo_Owner_aux__c != null ? acc.Codigo_Owner_aux__c : '';
                req.Assistente_comercial_xc =(String)acc.Assistente_comercial_aux__c != null ? acc.Assistente_comercial_aux__c : '';
                req.Mercado_xc = acc.Mercado__c != null ? acc.Mercado__c : '';
                req.Area_xc = acc.Area__c != null ? acc.Area__c : '';
                req.Plafond_comercial_xc = acc.Plafond_comercial__c != null ? String.valueOf(CurrencyConverter.convert(acc.Plafond_comercial__c, acc.CurrencyIsoCode, 'EUR')) : '0';
                req.Plafond_operacional_xc = acc.Plafond_comercial__c != null ? String.valueOf(CurrencyConverter.convert(acc.Plafond_operacional__c, acc.CurrencyIsoCode, 'EUR')) : '0';
                req.Documento_de_destino_xc =acc.Documento_de_destino__c != null ? acc.Documento_de_destino__c : '';
                req.Mercado_de_customizacoes_xc =acc.Mercado_de_customizacoes__c != null ? acc.Mercado_de_customizacoes__c : '';
                req.Diretor_comercial_xc =acc.Diretor_aux__c != null ? acc.Diretor_aux__c : '';
                req.Limite_operacional_de_divida_xc = acc.Limite_operacional_de_divida__c != null ? (Double) acc.Limite_operacional_de_divida__c : 0.0;
                req.Escalao_xc = acc.Escalao_Standard__c != null ? String.valueOf(acc.Escalao_Standard__c) : '';
                req.Vendedor_Nome_xc = acc.Owner_aux__c != null ? acc.Owner_aux__c : '';
                req.Tipologia_de_faturacao_xc = acc.Tipologia_de_facturacao__c != null ? acc.Tipologia_de_facturacao__c : '';
                req.Tipo = acc.Type != null ? acc.Type : '';
                req.Escalao_Hidea_xc = acc.Escalao_Hidea__c != null ? acc.Escalao_Hidea__c : '';
                req.Objectivo_de_faturacao_xc = acc.Objectivo_de_faturacao_anual__c != null ? CurrencyConverter.convert(acc.Objectivo_de_faturacao_anual__c, acc.CurrencyIsoCode, 'EUR') : 0.0;
                req.Limite_de_credito_comercial_xc = acc.Limite_de_credito_comercial__c != null ? acc.Limite_de_credito_comercial__c : 0.0;
                req.Macro_xc = acc.Marco__c != null ? acc.Marco__c : '';
                req.Notas_xc = acc.Notas_PHC__c != null ? acc.Notas_PHC__c : '';
                req.Cliente_anterior_xc = false;
                req.N_Cliente_anterior = 0.0;
                req.Tabela_Ligacao_cliente_xc = '';
                req.Rappel_xc = acc.Rappel__c != null ? (integer) acc.Rappel__c : 0;
                req.Incentivo_xc = acc.Incentivo__c != null ? (integer) acc.Incentivo__c : 0;
                req.Catalogo_xc = acc.Catalogo__c != null ? (integer) acc.Catalogo__c : 0;
                req.Amostras_xc = acc.Amostras__c != null ? CurrencyConverter.convert(acc.Amostras__c, acc.CurrencyIsoCode, 'EUR') : 0.0;
                req.Desconto_efectivo_xc = acc.Desconto_Efectivo__c != null ? acc.Desconto_Efectivo__c : 0;
                req.cod_user = [Select Alias From User Where Id = :UserInfo.getUserId()].Alias;
                req.outro_email_doc = acc.Outro_email_de_envio_de_documentos__c != null ? acc.Outro_email_de_envio_de_documentos__c : '';
                req.outro_email = acc.Outro_email__c != null ? acc.Outro_email__c : '';
                req.vip	= acc.VIP__c;
                req.atribManual	= acc.Atribuicao_zonas_manual__c;
                
                if(acc.Numero_de_cliente__c == '7025'){
                    system.debug(req);
                    system.debug(LoggingLevel.INFO, acc.Assistente_comercial_aux__c);
                }
                IntegratorClientes.servico.timeout_x = 120000;
                //pedido
                wsdl_Clientes.ClienteSalesToPHC resposta = IntegratorClientes.servico.actDadosClienteSalesForce(req);

                if(resposta.Bloqueado_xc != null) acc.Bloqueado__c = resposta.Bloqueado_xc;
                if(resposta.Tipo != null) acc.Type = resposta.Tipo;
                if(resposta.Encomendas_canceladas_xc != null) acc.Encomendas_canceladas__c = resposta.Encomendas_canceladas_xc;
                if(resposta.Contencioso_xc != null) acc.Contencioso__c = resposta.Contencioso_xc;
                //if(resposta.Vendedor_xc != null) acc.Vendedor__c = resposta.Vendedor_xc;
                if(resposta.Tabela_de_precos_xc != null) acc.Tabela_de_precos__c = resposta.Tabela_de_precos_xc;
                if(resposta.Objectivo_de_faturacao_xc != null) acc.Objectivo_de_faturacao_anual__c = CurrencyConverter.convert(resposta.Objectivo_de_faturacao_xc, 'EUR', acc.CurrencyIsoCode);
                if(resposta.Divida_nao_titulada_maturidade_xc != null) acc.Divida_nao_titulada_maturidade__c = resposta.Divida_nao_titulada_maturidade_xc;
                if(resposta.Divida_nao_titulada_saldo_xc != null) acc.Divida_nao_titulada_saldo__c = CurrencyConverter.convert(resposta.Divida_nao_titulada_saldo_xc, 'EUR', acc.CurrencyIsoCode);
                if(resposta.Divida_titulada_maturidade_xc != null) acc.Divida_titulada_maturidade__c = resposta.Divida_titulada_maturidade_xc;
                if(resposta.Divida_titulada_saldo_xc != null) acc.Divida_titulada_saldo__c = CurrencyConverter.convert(resposta.Divida_titulada_saldo_xc, 'EUR', acc.CurrencyIsoCode);
                if(resposta.Limite_de_credito_comercial_xc != null) acc.Limite_de_credito_comercial__c = resposta.Limite_de_credito_comercial_xc;
                if(resposta.Limite_operacional_de_divida_xc != null) acc.Limite_operacional_de_divida__c = resposta.Limite_operacional_de_divida_xc;
                if(resposta.Plafond_comercial_xc != null) acc.Plafond_comercial__c = CurrencyConverter.convert(resposta.Plafond_comercial_xc, 'EUR', acc.CurrencyIsoCode);
                if(resposta.Plafond_operacional_xc != null) acc.Plafond_operacional__c = CurrencyConverter.convert(resposta.Plafond_operacional_xc, 'EUR', acc.CurrencyIsoCode);
                if(resposta.Tipologia_de_faturacao_xc != null) acc.Tipologia_de_facturacao__c = resposta.Tipologia_de_faturacao_xc;
                if(resposta.Taxa_de_IVA_xc != null)acc.Taxa_de_IVA__c = resposta.Taxa_de_IVA_xc;
                if(resposta.Mercado_de_customizacoes_xc != null)acc.Mercado_de_customizacoes__c = (resposta.Mercado_de_customizacoes_xc != '' &&
                                                                                                   resposta.Mercado_de_customizacoes_xc != '0' &&
                                                                                                   resposta.Mercado_de_customizacoes_xc != null ) ? 
                    resposta.Mercado_de_customizacoes_xc : '';
                if(acc.Mercado_de_customizacoes__c != '') acc.Tabela_de_customizacoes__c = true;
                if(resposta.nomeEmpresa != null)acc.Name = resposta.nomeEmpresa;
                if(resposta.tabIVA != null)acc.Codigo_de_IVA__c = resposta.tabIVA;
                if(resposta.Vendas_ano_anterior != null)acc.Vendas_totais_ano_anterior__c = CurrencyConverter.convert(resposta.Vendas_ano_anterior, 'EUR', acc.CurrencyIsoCode);
                if(resposta.Vendas_ano_periodoHomologo != null)acc.Vendas_totais_ano_homologo__c = CurrencyConverter.convert(resposta.Vendas_ano_periodoHomologo, 'EUR', acc.CurrencyIsoCode);
                if(resposta.Vendas_ano_presente != null)acc.Vendas_totais_ano_presente__c = CurrencyConverter.convert(resposta.Vendas_ano_presente, 'EUR', acc.CurrencyIsoCode);
                if(resposta.Encomendas_Curso != null)acc.Em_curso__c = CurrencyConverter.convert(resposta.Encomendas_Curso, 'EUR', acc.CurrencyIsoCode);
                if(resposta.preNIF != null)acc.Prefixo_de_contribuinte__c = resposta.preNIF;
                if(resposta.NIF != null)acc.Numero_de_contribuinte__c = resposta.NIF;
                if(resposta.nomeab != null) acc.Nome_abreviado__c = resposta.nomeab;
                if(resposta.DividaVencida_xc != null) acc.Divida_vencida__c = CurrencyConverter.convert(resposta.DividaVencida_xc, 'EUR', acc.CurrencyIsoCode);
                if(resposta.Escalao_Hidea_xc != null) acc.Escalao_Hidea__c = resposta.Escalao_Hidea_xc;
                if(resposta.morPri != null) acc.Morada_principal__c = resposta.morPri;
            }catch(Exception ex){
                b_AtribZonasAccounts.errorMessages += 'Cliente: ' + acc + ' \r\nException: ' + ex.getMessage() + ' ; Line: ' + ex.getLineNumber();
                errorMessage += 'Cliente: ' + acc + ' \r\nException: ' + ex.getMessage() + ' ; Line: ' + ex.getLineNumber();
            }
        }
    }
}