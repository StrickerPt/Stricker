public class IntegratorClientes {
    public static wsdl_Clientes.ClientePHCSoap servico = new wsdl_Clientes.ClientePHCSoap();
    
    @future(callout=true)
    public static void createCustomer(Set<Id> leadsToConvert){
        /*INACTIVO A PARTIR DE 08-05-2018*/
        checkRecursive.runFalse();
        Map<Id, Lead> leads = new Map<Id, Lead>([select id, Name, Comercial__r.Name, Numero_de_contribuinte__c, Nome_abreviado__c, Phone, MobilePhone, Street, City, PostalCode, State, Tipo__c, Comercial__r.Codigo_de_Utilizador__c,
                                                 Email, Plafond_comercial__c, CountryCode, Bloqueado__c, Limite_de_credito_comercial__c, Website, Prefixo_de_contribuinte__c, Idioma_para_faturacao__c, Inativo__c,
                                                 Encomendas_canceladas__c, IBAN__c, Divida_titulada_saldo__c, Tabela_de_precos__c, Divida_titulada_maturidade__c, Plafond_operacional__c, Limite_operacional_de_divida__c,
                                                 Tipologia_de_faturacao__c, Divida_nao_titulada_maturidade__c, Escalao_Hidea__c, Objetivo_de_faturacao__c, Owner.Name, Divida_nao_titulada_saldo__c,Username__c,
                                                 Idioma_de_comunicacao__c, Diretor_Comercial__r.Name, Mercado_de_customizacoes__c, Divida_vencida__c, Documento_de_destino__c, Mercado__c, Macro__c, Area__c,
                                                 Email_para_documentos__c, CurrencyIsoCode, Rappel__c, Incentivo__c, Catalogo__c, Amostras__c, Desconto_Efectivo__c, Isento_de_IVA__c, Escalao_Standard__c, Cliente_anterior__c,
                                                 Company,Zona__c,Numero_de_cliente__c
                                                 From Lead Where Id In :leadsToConvert and isConverted = false/* and Numero_de_cliente__c = null*/]);
        User user = [Select Id, Codigo_de_Utilizador__c,Alias From User Where Id = :UserInfo.getUserId()];
        boolean isSucess = true;
        for(Lead l : leads.values()){
            if(l.Numero_de_cliente__c == null || l.Numero_de_cliente__c == ''){
                
                wsdl_Clientes.ClienteSalesInsertPHC req = new wsdl_Clientes.ClienteSalesInsertPHC();
                req.nomeEmpresa = l.Company != null ? l.Company : l.Name != null ? l.Name : '';
                req.vend_nome = l.Comercial__r.Name != null ? l.Comercial__r.Name : '';
                req.nif = l.Numero_de_contribuinte__c != null ?  l.Numero_de_contribuinte__c : '';
                req.nomeab = l.Nome_abreviado__c != null ? l.Nome_abreviado__c : '';
                req.phone = l.Phone != null ? l.Phone : '';
                req.morada = l.Street != null ? l.Street : '';
                req.local = l.City != null ? l.City : '';
                req.cod_post = l.PostalCode != null ? l.PostalCode : '';
                req.zona = l.Zona__c != null ? l.Zona__c : '';
                req.tipo = 'C';//valor default C adicionado a 2018-09-26
                req.vend_cod = l.Comercial__r.Codigo_de_Utilizador__c != null ? l.Comercial__r.Codigo_de_Utilizador__c : '';
                req.email = l.Email != null ? l.Email : '';
                req.plafond_comercial = l.Plafond_comercial__c != null ? CurrencyConverter.convert(l.Plafond_comercial__c, l.CurrencyIsoCode, 'EUR') : 0.0;
                req.pais = l.CountryCode != null ? l.CountryCode : '';
                req.bloqueado = l.Bloqueado__c;
                req.lim_cred_comercial = l.Limite_de_credito_comercial__c != null ? (Integer) l.Limite_de_credito_comercial__c : 0;
                req.website = l.Website != null ? l.Website : '';
                req.preNIF = l.Prefixo_de_contribuinte__c != null ? l.Prefixo_de_contribuinte__c : '';
                req.idioma_fat = l.Idioma_para_faturacao__c != null ? l.Idioma_para_faturacao__c : '';
                req.inativo = l.Inativo__c;
                req.enc_canceladas = true;//l.Encomendas_canceladas__c; 03-07-2018
                req.iban = l.IBAN__c != null ? l.IBAN__c : '';
                req.div_titulada_saldo = l.Divida_titulada_saldo__c != null ? CurrencyConverter.convert(l.Divida_titulada_saldo__c, l.CurrencyIsoCode, 'EUR')  : 0.0;
                req.tab_precos = l.Tabela_de_precos__c != null && l.Tabela_de_precos__c.isNumeric() ? Integer.valueOf(l.Tabela_de_precos__c) : 0;
                req.div_titulada_maturidade = l.Divida_titulada_maturidade__c != null ? (Integer) CurrencyConverter.convert(l.Divida_titulada_maturidade__c, l.CurrencyIsoCode, 'EUR') : 0;
                req.plafond_operacional = l.Plafond_operacional__c != null ? CurrencyConverter.convert(l.Plafond_operacional__c, l.CurrencyIsoCode, 'EUR') : 0.0;
                req.lim_oper_divida = l.Limite_operacional_de_divida__c != null ? (Integer) CurrencyConverter.convert(l.Limite_operacional_de_divida__c, l.CurrencyIsoCode, 'EUR') : 0;
                req.tipo_fat = '';//l.Tipologia_de_faturacao__c != null ? l.Tipologia_de_faturacao__c : '';
                req.div_nao_titulada_maturidade = l.Divida_nao_titulada_maturidade__c != null ? (Integer) CurrencyConverter.convert(l.Divida_nao_titulada_maturidade__c, l.CurrencyIsoCode, 'EUR') : 0;
                req.escalao_hidea = l.Escalao_Hidea__c != null ? l.Escalao_Hidea__c : '';
                req.cod_user = user.Alias != null ? user.Alias : '';
                req.obj_fat = l.Objetivo_de_faturacao__c != null ? CurrencyConverter.convert(l.Objetivo_de_faturacao__c, l.CurrencyIsoCode, 'EUR')  : 0.0;
                req.assistent = l.Owner.Name != null ? l.Owner.Name : '';
                req.div_nao_titulada_saldo = l.Divida_nao_titulada_saldo__c != null ? CurrencyConverter.convert(l.Divida_nao_titulada_saldo__c, l.CurrencyIsoCode, 'EUR') : 0.0;
                req.idioma = l.Idioma_de_comunicacao__c != null ? l.Idioma_de_comunicacao__c : '';
                req.dir_comercial = l.Diretor_Comercial__r != null ? l.Diretor_Comercial__r.Name : '';
                req.merc_cust = l.Mercado_de_customizacoes__c != null ? l.Mercado_de_customizacoes__c : '';
                req.divida_vencida = l.Divida_vencida__c != null ? CurrencyConverter.convert(l.Divida_vencida__c, l.CurrencyIsoCode, 'EUR') : 0.0;
                req.doc_dest = l.Documento_de_destino__c != null ? l.Documento_de_destino__c : '';
                req.merc = l.Mercado__c != null ? l.Mercado__c : '';
                req.macro = l.Macro__c != null ? l.Macro__c : '';
                req.area = l.Area__c != null ? l.Area__c : '';
                req.email_docs = l.Email != null ? l.Email : '';//l.Email_para_documentos__c != null ? l.Email_para_documentos__c : ''; 03-07-2018
                req.moeda = l.CurrencyIsoCode != null ? l.CurrencyIsoCode : '';
                req.rappel = l.Rappel__c != null ? l.Rappel__c : 0.0;
                req.incentiv = l.Incentivo__c != null ? l.Incentivo__c : 0.0;
                req.catalogo = l.Catalogo__c != null ? l.Catalogo__c : 0.0;
                req.amostras = l.Amostras__c != null ? CurrencyConverter.convert(l.Amostras__c, l.CurrencyIsoCode, 'EUR') : 0.0;
                req.descefec = l.Desconto_Efectivo__c != null ? l.Desconto_Efectivo__c : 0.0;
                req.validouIsento = l.Isento_de_IVA__c;
                req.esc_standard = l.Escalao_Standard__c;
                req.cliente_anterior = l.Cliente_anterior__c != null;
                req.n_cliente_anterior = l.Cliente_anterior__c != null && l.Cliente_anterior__c.isNumeric() ? Integer.valueOf(l.Cliente_anterior__c) : 0;
                req.tabela_ligacao_cliente = '';
                req.userName = l.Username__c != null ? l.Username__c : '';
                
                servico.timeout_x = 120000;
                wsdl_Clientes.INCliente_PHC newClient = servico.criaClientePHC(req);//nomeVendedor
                
                system.debug(newClient);
                if(newClient.Numero_de_cliente_xc != 0){
                    
                    l.Numero_de_cliente__c = string.valueOf(newClient.Numero_de_cliente_xc != null ? newClient.Numero_de_cliente_xc : 1);
                    l.Tipo__c = newClient.type_x;
                    l.Escalao_Hidea__c = newClient.Escalao_Hidea_xc;
                    l.Tabela_de_precos__c = newClient.Tabela_de_precos_xc;
                    //l.Prazo_de_pagamento__c = newClient.Prazo_de_pagamento_xc;
                    l.Limite_de_credito_comercial__c = newClient.Limite_de_credito_comercial_xc;
                    l.Limite_operacional_de_divida__c = newClient.Limite_operacional_de_divida_xc;
                    l.Plafond_comercial__c = CurrencyConverter.convert(newClient.Plafond_comercial_xc, l.CurrencyIsoCode, 'EUR');
                    l.Plafond_operacional__c = CurrencyConverter.convert(newClient.Plafond_operacional_xc, l.CurrencyIsoCode, 'EUR');
                    l.Divida_nao_titulada_maturidade__c = newClient.Divida_nao_titulada_maturidade_xc;
                    l.Divida_nao_titulada_saldo__c = CurrencyConverter.convert(newClient.Divida_nao_titulada_saldo_xc, l.CurrencyIsoCode, 'EUR');
                    l.Divida_titulada_maturidade__c = newClient.Divida_titulada_maturidade_xc;
                    l.Divida_titulada_saldo__c = CurrencyConverter.convert(newClient.Divida_titulada_saldo_xc, l.CurrencyIsoCode, 'EUR');
                    l.Divida_vencida__c = CurrencyConverter.convert(newClient.DividaVencida_xc, l.CurrencyIsoCode, 'EUR');
                    //l.Vendas_ano_anterior__c = newClient.Vendas_ano_anterior;
                    //l.Encomendas_Curso__c = newClient.Encomendas_Curso;
                    //l.Vendas_ano_presente__c = newClient.Vendas_ano_presente;
                    //l.Vendas_ano_periodoHomologo__c = newClient.Vendas_ano_periodoHomologo;
                    l.Encomendas_canceladas__c = newClient.Encomendas_canceladas_xc;
                    l.Bloqueado__c = newClient.Bloqueado_xc;
                    l.Contencioso__c = newClient.Contencioso_xc;
                    l.Tipologia_de_faturacao__c = newClient.tipo_fat;
                }
                else {
                    isSucess = false;
                    String body = 'Lead: ' + l.Id + '\r\n User: ' + UserInfo.getUserName() + '\r\n Foi devolvido número de cliente = 0;';
                    UtilClaims.sendEmailFailure('Falha na criação de cliente', body);
                } 
            }
        }
        try{
            if(isSucess){
                system.debug(leads.values());
                update leads.values();
                List<Database.LeadConvert> leadsConvert = new List<Database.LeadConvert>();
                for(Lead l : leads.values()){
                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setConvertedStatus('Qualificada');
                    lc.setLeadId(l.id);
                    lc.setDoNotCreateOpportunity(true);//não cria oportunidade
                    
                    leadsConvert.add(lc);
                    
                }
                if(!leadsConvert.isEmpty()){
                    Database.LeadConvertResult[] lcr = Database.convertLead(leadsConvert);
                    List<Morada_de_entrega__c> moradas = new List<Morada_de_entrega__c>();
                    Set<Id> accsId = new Set<Id>();
                    Set<Id> contactsId = new Set<Id>();
                    for(Database.LeadConvertResult lead : lcr){
                        if(lead.isSuccess()){
                            accsId.add(lead.getAccountId());
                            contactsId.add(lead.getContactId());
                            Morada_de_entrega__c morada = new Morada_de_entrega__c();
                            morada.Conta__c = lead.getAccountId();
                            morada.Morada_de_entrega__c = leads.get(lead.getLeadId()).Street;
                            morada.Codigo_postal__c =  leads.get(lead.getLeadId()).PostalCode;
                            morada.Nome_da_empresa__c =  leads.get(lead.getLeadId()).Company != null ? leads.get(lead.getLeadId()).Company : leads.get(lead.getLeadId()).Name;
                            morada.Localidade__c = leads.get(lead.getLeadId()).City;
                            morada.Pais__c = leads.get(lead.getLeadId()).CountryCode;
                            morada.Telefone_logistico__c = leads.get(lead.getLeadId()).Phone != null ? leads.get(lead.getLeadId()).Phone : leads.get(lead.getLeadId()).MobilePhone;
                            
                            moradas.add(morada);
                        }
                    }
                    checkRecursive.runMoradaCliente = true;
                    insert moradas;
                    DateTime now  = DateTime.now();
                    String nowToString = String.ValueOf(now);
                    DateTime nextRunTime = now.addSeconds(10);
                    String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
                    
                    sh_AfterConvert sc = new sh_AfterConvert(accsId, new Map<Id, Morada_de_entrega__c>(moradas).keySet(), contactsId);
                    System.schedule('Criar morada após convert: '+nowToString, cronString, sc);
                }
            }
        }catch(Exception ex){
            UtilClaims.sendEmailFailure('Falha criação de cliente', 'Lead: ' + leads.values() + ' \r\nException: ' +ex.getMessage());
        }
    }
     
    public static Decimal consultaSaldoCliente(Integer nCliente){
        return servico.consultaSaldoCliente_PHC(nCliente);
    }
    
    
}