public with sharing class PlantforceDashboardController {

    // Wrapper class for Crisis Data points
    private class CrisisDataPoint {
        Date recordDate;
        Decimal pressureSum = 0;
        Decimal temperatureSum = 0;
        Integer count = 0;

        CrisisDataPoint(Date dt) {
            this.recordDate = dt;
        }

        void addRecord(Decimal pressure, Decimal temperature) {
            if (pressure != null) this.pressureSum += pressure;
            if (temperature != null) this.temperatureSum += temperature;
            this.count++;
        }

        Decimal getAvgPressure() {
            return (count > 0 && pressureSum != null) ? pressureSum / count : 0;
        }

        Decimal getAvgTemperature() {
            return (count > 0 && temperatureSum != null) ? temperatureSum / count : 0;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<Object>> getCrisisData() {
        Map<String, List<Object>> result = new Map<String, List<Object>>();
        List<Object> labels = new List<Object>();
        List<Object> pressureData = new List<Object>();
        List<Object> temperatureData = new List<Object>();
        Map<Date, CrisisDataPoint> dailyDataMap = new Map<Date, CrisisDataPoint>();

        try {
            Date today = Date.today();
            // Go back 11 days to ensure we have data for the last 10 full days potentially
            Date startDate = today.addDays(-11);
            // Create a Datetime for comparison in SOQL
            Datetime startDateTime = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));

            // Query records using generic SObject type
            // Simplify date comparison
            List<SObject> crisisRecords = Database.query(
                'SELECT crisis_time__c, pressure_val__c, temperature_val__c ' +
                'FROM crisismanagementcsv_aws_s3__dlm ' + // Assuming this one is correct for now
                'WHERE crisis_time__c >= :startDateTime ' + // Compare directly with start datetime
                'ORDER BY crisis_time__c ASC ' +
                'LIMIT 500'
            );

            // Aggregate data by day (using SObject)
            for (SObject record : crisisRecords) {
                Datetime crisisTime = (Datetime)record.get('crisis_time__c');
                if (crisisTime != null) {
                    Date recordDate = crisisTime.date();
                    // Filter for the exact 10-day window (today and 9 days prior)
                    // Note: The SOQL query fetches slightly more, filtering here is precise.
                    if (recordDate >= today.addDays(-9) && recordDate <= today) {
                         if (!dailyDataMap.containsKey(recordDate)) {
                            dailyDataMap.put(recordDate, new CrisisDataPoint(recordDate));
                        }
                        Decimal pressure = (Decimal)record.get('pressure_val__c');
                        Decimal temperature = (Decimal)record.get('temperature_val__c');
                        dailyDataMap.get(recordDate).addRecord(pressure, temperature);
                    }
                }
            }
            
            // Generate labels and data for the last 10 days, filling gaps
            List<Date> sortedDates = new List<Date>(dailyDataMap.keySet());
            sortedDates.sort();

            Map<Date, CrisisDataPoint> finalDailyData = new Map<Date, CrisisDataPoint>();
            // Ensure we have entries for the last 10 days exactly
             for (Integer i = 0; i < 10; i++) {
                Date targetDate = today.addDays(-9 + i);
                labels.add(targetDate.format()); // Format date as string label
                if(dailyDataMap.containsKey(targetDate)){
                    finalDailyData.put(targetDate, dailyDataMap.get(targetDate));
                    pressureData.add(dailyDataMap.get(targetDate).getAvgPressure());
                    temperatureData.add(dailyDataMap.get(targetDate).getAvgTemperature());
                } else {
                    // Add 0 or null for days with no data
                    pressureData.add(0); 
                    temperatureData.add(0);
                }
            }


            result.put('labels', labels);
            result.put('pressureData', pressureData);
            result.put('temperatureData', temperatureData);

        } catch (Exception e) {
            System.debug('Error fetching crisis data: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Error fetching crisis data: ' + e.getMessage());
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<Object>> getMachineData() {
        Map<String, List<Object>> result = new Map<String, List<Object>>();
        List<Object> labels = new List<Object>();
        List<Object> rawMaterial1Data = new List<Object>();
        List<Object> rawMaterial2Data = new List<Object>();
        // Use a map with generic SObject
        Map<String, SObject> latestMachineData = new Map<String, SObject>();

        try {
            // Query machine data using generic SObject type
            // Revert to __dll based on the error message
            List<SObject> machineRecords = Database.query(
                'SELECT machineid__c, rawmaterialused1qty__c, rawmaterialused2qty__c ' +
                'FROM machinescsv_aws_s3__dll ' + // Changed back to __dll
                'ORDER BY machineid__c ASC ' +
                'LIMIT 100'
            );

            // Process records (using SObject)
             for(SObject record : machineRecords) {
                String machineId = (String)record.get('machineid__c');
                if (String.isNotBlank(machineId)) {
                    latestMachineData.put(machineId, record);
                }
            }

            // Extract data for the chart
            List<String> machineIds = new List<String>(latestMachineData.keySet());
            machineIds.sort(); // Sort machine IDs for consistent order

            for(String machineId : machineIds) {
                SObject record = latestMachineData.get(machineId); // Use generic SObject
                labels.add(machineId);
                // Get values using get() and handle potential nulls
                Decimal rm1 = (Decimal)record.get('rawmaterialused1qty__c');
                Decimal rm2 = (Decimal)record.get('rawmaterialused2qty__c');
                rawMaterial1Data.add(rm1 != null ? rm1 : 0);
                rawMaterial2Data.add(rm2 != null ? rm2 : 0);
            }

            result.put('labels', labels);
            result.put('rawMaterial1Data', rawMaterial1Data);
            result.put('rawMaterial2Data', rawMaterial2Data);

        } catch (Exception e) {
            System.debug('Error fetching machine data: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Error fetching machine data: ' + e.getMessage());
        }

        return result;
    }
}
