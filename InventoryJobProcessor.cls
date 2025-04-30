public with sharing class InventoryJobProcessor {

    public class JobLogInput {
        @InvocableVariable public String inventoryid;
        @InvocableVariable public String product;
        @InvocableVariable public Boolean israwmaterial;
        @InvocableVariable public String warehouse_loc;
        @InvocableVariable public Integer quantity_available;
        @InvocableVariable public Integer min_stock_level;
        @InvocableVariable public Integer max_stock_level;
        @InvocableVariable public Date lastupdated;
        @InvocableVariable public Date expiry_date;
        @InvocableVariable public String jobStatus;
        @InvocableVariable public String rawmaterialused1name;
        @InvocableVariable public String rawmaterialused2name;
        @InvocableVariable public Integer rawmaterialused1qty;
        @InvocableVariable public Integer rawmaterialused2qty;
    }

    @InvocableMethod(label='Process Machine Job Log')
    public static List<JobLogOutput> processJob(List<JobLogInput> inputs) {
        List<JobLogOutput> results = new List<JobLogOutput>();

        for (JobLogInput input : inputs) {
            List<inventory__c> toUpdate = new List<inventory__c>();
            String msg = '';

            try {
                if (input.jobStatus == 'success') {
                    inventory__c finished = new inventory__c(
                        inventoryid__c = input.inventoryid,
                        product__c = input.product,
                        israwmaterial__c = input.israwmaterial,
                        warehouse_loc__c = input.warehouse_loc,
                        quantity_available__c = input.quantity_available,
                        min_stock_level__c = input.min_stock_level,
                        max_stock_level__c = input.max_stock_level,
                        lastupdated__c = input.lastupdated,
                        expiry_date__c = input.expiry_date
                    );
                    insert finished;
                    msg += '✔ Inserted finished product ' + input.product + '. ';
                }

                if (String.isNotBlank(input.rawmaterialused1name)) {
                    List<inventory__c> mat1List = [
                        SELECT Id, quantity_available__c
                        FROM inventory__c
                        WHERE product__c = :input.rawmaterialused1name AND israwmaterial__c = true
                        LIMIT 1
                    ];
                    if (!mat1List.isEmpty()) {
                        inventory__c mat1 = mat1List[0];
                        mat1.quantity_available__c -= input.rawmaterialused1qty;
                        toUpdate.add(mat1);
                        msg += 'Updated ' + input.rawmaterialused1name + ' -' + input.rawmaterialused1qty + '. ';
                    }
                }

                if (String.isNotBlank(input.rawmaterialused2name)) {
                    List<inventory__c> mat2List = [
                        SELECT Id, quantity_available__c
                        FROM inventory__c
                        WHERE product__c = :input.rawmaterialused2name AND israwmaterial__c = true
                        LIMIT 1
                    ];
                    if (!mat2List.isEmpty()) {
                        inventory__c mat2 = mat2List[0];
                        mat2.quantity_available__c -= input.rawmaterialused2qty;
                        toUpdate.add(mat2);
                        msg += 'Updated ' + input.rawmaterialused2name + ' -' + input.rawmaterialused2qty + '.';
                    }
                }

                if (!toUpdate.isEmpty()) {
                    update toUpdate;
                }

            } catch (Exception e) {
                msg += '⚠ Error: ' + e.getMessage();
            }

            JobLogOutput out = new JobLogOutput();
            out.message = msg;
            results.add(out);
        }

        return results;
    }
}