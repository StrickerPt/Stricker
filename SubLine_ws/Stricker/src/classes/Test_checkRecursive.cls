@isTest
public class Test_checkRecursive {

    static testmethod void test1() {
        checkRecursive.runAccount = true;
        checkRecursive.runContact = true;
        checkRecursive.runLead = true;
        checkRecursive.runOpportunityAfterUpdate = true;
        checkRecursive.runDocs = true;
        checkRecursive.runOpportunityBeforeUpdate = true;
        checkRecursive.runExpFile = true;
        checkRecursive.runDeleteOpps = true;
        checkRecursive.runRequestOpps = true;
        checkRecursive.runMoradaCliente = true;
        checkRecursive.runCase = true;
        checkRecursive.runOrderItem = true;
        checkRecursive.runPrecoCliente = true;
        
        checkRecursive.runFalse();
    }
}