echo Importing from CSV writing results to tmp/import_results.txt
NO_HTTP_LOGGER=1 bundle exec rake measurements_api:import_csv_data[tmp/sql_server_csv_dump] > tmp/import_results.txt
