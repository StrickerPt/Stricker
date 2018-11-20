public class checkRecursive {
    public static Boolean runAccount = true;//Run account trigger
    public static Boolean runContact = true;//Run contact trigger
    public static Boolean runLead = true;//Run Lead trigger
    public static Boolean runOpportunityAfterUpdate = true;//Run after update opportunity trigger
    public static Boolean runDocs = true;//Run Documentos_Financeiros__c trigger
    public static Boolean runOpportunityBeforeUpdate = true;//Run before update opportunity trigger
    public static Boolean runExpFile = true;//Run export file
    public static Boolean runDeleteOpps = true;//Run error delete opps
    public static Boolean runRequestOpps = true;//Send Webservice request through trigger
    public static Boolean runMoradaCliente = true;//Run runMoradaCliente trigger
    public static Boolean runCase = true;//Run Case trigger
    public static Boolean runOrderItem = true;//Run OrderItem trigger
    public static Boolean runPrecoCliente = true;//Run Preco_por_cliente__c trigger
    public static Boolean runRecalcExp = false;//Run Preco_por_cliente__c trigger
    
    public static void runFalse(){
        runAccount = false;
        runContact = false;
        runLead = false;
        runOpportunityAfterUpdate = false;
        runDocs = false;
        runOpportunityBeforeUpdate = false;
        runExpFile = false;
        runDeleteOpps = false;
        runRequestOpps = false;
        runMoradaCliente = false;
        runCase = false;
        runOrderItem = false;
        runPrecoCliente = false;
    }
}