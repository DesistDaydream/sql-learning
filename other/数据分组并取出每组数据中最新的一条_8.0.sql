SELECT *
FROM(
        SELECT ROW_NUMBER() OVER (
                PARTITION BY lake.name,
                net.name
                ORDER BY diversion.updated_at desc
            ) AS row_num,
            lake.name as datalakeName,
            net.name as privateNetName,
            glacier_node_count,
            glacier_total_size,
            glacier_used_size,
            glacier_used_size / glacier_total_size AS glacier_usage_percentage,
            standard_node_count,
            standard_total_size,
            standard_used_size,
            standard_used_size / standard_total_size AS standard_usage_percentage,
            diversion.updated_at AS updated_at
        FROM t_diversion diversion
            left join t_data_lake lake on diversion.data_lake_code = lake.code
            left join t_private_net net on diversion.private_net_code = net.code
        WHERE diversion.is_deleted = 0
    ) t
WHERE row_num = 1