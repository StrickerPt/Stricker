public class c_SincronizarCliente {
    public Account acc {get;set;}
    public boolean success {get;set;}
    public c_SincronizarCliente(ApexPages.StandardController ctrl){
        acc = [Select Id, Numero_de_cliente__c From Account Where Id = :ctrl.getId()];
        success = false;
    }
    
    public void callSync(){
        /*if(acc.Numero_de_cliente__c != '0' && acc.Numero_de_cliente__c != null){
            clientStricker.INCliente_PHC resp = Integrator.servico.consultaINCliente_PHC(Integer.valueOf(acc.Numero_de_cliente__c));
            
            acc.Escalao_Hidea__c = resp.Escalao_Hidea_xc;
            acc.Tabela_de_precos__c = resp.Tabela_de_precos_xc;
            acc.Limite_de_credito_comercial__c = resp.Prazo_de_pagamento_xc;
            acc.Limite_de_credito_comercial__c = resp.Limite_de_credito_comercial_xc;
            acc.Limite_operacional_de_divida__c = resp.Limite_operacional_de_divida_xc;
            acc.Plafond_comercial__c = resp.Plafond_comercial_xc;
            acc.Plafond_operacional__c = resp.Plafond_operacional_xc;
            acc.Divida_nao_titulada_maturidade__c = resp.Divida_nao_titulada_maturidade_xc;
            acc.Divida_nao_titulada_saldo__c = resp.Divida_nao_titulada_saldo_xc;
            acc.Divida_titulada_maturidade__c = resp.Divida_titulada_maturidade_xc;
            acc.Divida_titulada_saldo__c = resp.Divida_titulada_saldo_xc;
            acc.Divida_vencida__c = resp.DividaVencida_xc;
            acc.Vendas_totais_ano_anterior__c = resp.Vendas_ano_anterior;
            acc.Em_curso__c = resp.Encomendas_Curso;
            acc.Vendas_totais_ano_presente__c = resp.Vendas_ano_presente;
            acc.Vendas_totais_ano_homologo__c = resp.Vendas_ano_periodoHomologo;
            acc.Encomendas_canceladas__c = resp.Encomendas_canceladas_xc;
            acc.Bloqueado__c = resp.Bloqueado_xc;
            acc.Contencioso__c = resp.Contencioso_xc;
            
            checkRecursive.runAccount = false;
            update acc;
            success = true;
        }else{
            success = false;
        }*/
    }
}