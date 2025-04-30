public class DataCloudInventoryQueryExecutor {

    public class InputWrapper {
        @InvocableVariable(required=true)
        public String sqlQuery;
    }

    @InvocableMethod(label='Execute Data Cloud Inventory Query' description='Executes a SQL query on Data Cloud and returns results')
    public static List<DataCloudInventoryQueryOutputWrapper> executeQuery(List<InputWrapper> inputs) {
        List<DataCloudInventoryQueryOutputWrapper> results = new List<DataCloudInventoryQueryOutputWrapper>();
        for (InputWrapper input : inputs) {
            DataCloudInventoryQueryOutputWrapper output = new DataCloudInventoryQueryOutputWrapper();
            try {
                ConnectApi.CdpQueryInput queryInput = new ConnectApi.CdpQueryInput();
                queryInput.sql = input.sqlQuery;
                ConnectApi.CdpQueryOutputV2 response = ConnectApi.CdpQuery.queryAnsiSqlV2(queryInput);

                output.queryResult = JSON.serialize(response);
            } catch (Exception e) {
                output.queryResult = 'Error: ' + e.getMessage();
            }
            results.add(output);
        }
        return results;
    }
}