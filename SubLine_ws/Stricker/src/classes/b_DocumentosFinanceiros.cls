global class b_DocumentosFinanceiros implements Schedulable{

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new b_DocumentosFinanceirosPHC(), 1);
        Database.executeBatch(new b_DocumentosFinanceirosIT(), 1);
        Database.executeBatch(new b_DocumentosFinanceirosDE(), 1);
        Database.executeBatch(new b_DocumentosFinanceirosUK(), 1);  //2018/10/03
    }
}