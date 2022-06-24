SELECT datalakeName,
    privateNetName,
    glacier_node_count,
    glacier_total_size,
    glacier_used_size,
    glacier_used_size / glacier_total_size AS glacier_usage_percentage,
    standard_node_count,
    standard_total_size,
    standard_used_size,
    standard_used_size / standard_total_size AS standard_usage_percentage
FROM (
        -- 分组编号
        -- 为结果表添加3个新列，列名为 rowNum、lake、net
        -- **处理第1行数据，此时 r="" lake="" net=""**
        -- 判断 lake != tab.data_lake_code(第1行) net != tab.private_net_code(第1行),所以
        -- 第一列 rowNum=1
        -- 第二列 lake=tab.data_lake_code(第1行)
        -- 第三列 net=tab.private_net_code(第1行)
        --
        -- **处理第2行数据，此时 r=1 lake=tab.data_lake_code(第1行) net=tab.private_net_code(第1行)**
        -- 第一列 由于 lake = tab.data_lake_code(第2行),rowNum=rowNum+1=2
        -- 第二列 lake=tab.data_lake_code(第2行)
        -- 第三列 net=tab.private_net_code(第2行)
        --
        -- **处理第3行数据，此时 r=2 lake=tab.data_lake_code(第2行) net=tab.private_net_code(第2行)**
        -- 第一列 rowNum=rowNum+1=3
        -- 第二列 lake=tab.data_lake_code(第3行)
        -- 第三列 net=tab.private_net_code(第3行)
        --
        -- **处理第4条数据，此时 r=3 lake=tab.data_lake_code(第3行) net=tab.private_net_code(第3行)**
        -- ......略
        --
        -- **处理第233条数据，此时 r=232 lake=tab.data_lake_code(第232行) net=tab.private_net_code(第232行)**
        -- 判断 lake != tab.data_lake_code(第233行) net != tab.private_net_code(第233行),所以
        -- 第一列 rowNum=1
        -- 至此，根据 lake 和 net 分组完成，每组数据最新一条的 rowNum 值为 1，以供后续语句取最新值使用
        SELECT @r := case
                when @lake = tab.data_lake_code
                and @net = tab.private_net_code then @r + 1
                else 1
            end as rowNum,
            @lake := tab.data_lake_code as lake,
            @net := tab.private_net_code as net,
            -- 临时生成的 tab 表的所有行
            tab.*
        FROM (
                -- 选择出所有时间的存储数据，并按照创建时间从新到旧排序
                SELECT diversion.id,
                    diversion.data_lake_code,
                    diversion.private_net_code,
                    diversion.standard_total_size,
                    diversion.standard_used_size,
                    diversion.standard_node_count,
                    diversion.glacier_total_size,
                    diversion.glacier_used_size,
                    diversion.glacier_node_count,
                    diversion.is_deleted,
                    diversion.created_at,
                    diversion.updated_at,
                    lake.name as datalakeName,
                    net.name as privateNetName,
                    geo.name as geoName
                FROM t_diversion diversion
                    left join t_data_lake lake on diversion.data_lake_code = lake.code
                    left join t_private_net net on diversion.private_net_code = net.code
                    left join t_geo_division geo on geo.id = lake.geo_id
                WHERE diversion.is_deleted = 0
                ORDER BY diversion.created_at desc
            ) tab
        ORDER BY data_lake_code,
            private_net_code,
            created_at desc
    ) allTab
WHERE rowNum = 1
ORDER BY geoName,
    data_lake_code,
    private_net_code;