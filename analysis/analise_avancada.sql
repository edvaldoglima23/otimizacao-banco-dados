-- --------------------------------------------------------
-- Análise Avançada de Performance do Banco de Dados
-- Scripts para diagnóstico e otimização
-- --------------------------------------------------------

-- --------------------------------------------------------
-- 1. Análise de Tabelas e Fragmentação
-- --------------------------------------------------------

-- Identifica tabelas fragmentadas que podem se beneficiar de otimização
SELECT 
    table_schema as banco,
    table_name as tabela,
    engine,
    row_format as formato_linha,
    table_rows as linhas,
    avg_row_length as tamanho_medio_linha,
    ROUND((data_length + index_length) / 1024 / 1024, 2) as tamanho_total_mb,
    ROUND(data_length / 1024 / 1024, 2) as tamanho_dados_mb,
    ROUND(index_length / 1024 / 1024, 2) as tamanho_indices_mb,
    ROUND(data_free / 1024 / 1024, 2) as espaco_nao_utilizado_mb,
    ROUND((data_free / (data_length + index_length)) * 100, 2) as fragmentacao_percentual
FROM 
    information_schema.tables
WHERE 
    table_schema = DATABASE()
    AND table_type = 'BASE TABLE'
HAVING 
    fragmentacao_percentual > 10
ORDER BY 
    fragmentacao_percentual DESC;

-- --------------------------------------------------------
-- 2. Análise de Consultas Lentas
-- --------------------------------------------------------

-- Configurar o log de consultas lentas
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1.0; -- Registra consultas que demoram mais de 1 segundo
SET GLOBAL slow_query_log_file = '/var/log/mysql/mysql-slow.log';

-- Consulta para identificar consultas lentas do log (após configuração)
-- Exemplo de análise manual do log slow query:
/*
mysqldumpslow -s t -t 10 /var/log/mysql/mysql-slow.log
*/

-- --------------------------------------------------------
-- 3. Análise de Uso de Índices
-- --------------------------------------------------------

-- Identifica índices não utilizados
SELECT 
    t.TABLE_SCHEMA as banco,
    t.TABLE_NAME as tabela,
    s.INDEX_NAME as indice,
    s.SEQ_IN_INDEX as sequencia,
    s.COLUMN_NAME as coluna,
    i.NON_UNIQUE as nao_unico,
    IFNULL(h.COUNT_STAR, 0) as total_acessos,
    IFNULL(h.COUNT_READ, 0) as total_leituras,
    IFNULL(h.COUNT_WRITE, 0) as total_escritas,
    CASE 
        WHEN h.COUNT_STAR IS NULL OR h.COUNT_STAR = 0 THEN 'NÃO UTILIZADO'
        WHEN h.COUNT_STAR < 10 THEN 'POUCO UTILIZADO'
        ELSE 'UTILIZADO'
    END as status_utilizacao
FROM 
    information_schema.STATISTICS s
JOIN 
    information_schema.TABLES t ON s.TABLE_SCHEMA = t.TABLE_SCHEMA AND s.TABLE_NAME = t.TABLE_NAME
JOIN 
    information_schema.STATISTICS i ON s.TABLE_SCHEMA = i.TABLE_SCHEMA AND s.TABLE_NAME = i.TABLE_NAME AND s.INDEX_NAME = i.INDEX_NAME
LEFT JOIN 
    performance_schema.table_io_waits_summary_by_index_usage h ON h.OBJECT_SCHEMA = s.TABLE_SCHEMA AND h.OBJECT_NAME = s.TABLE_NAME AND h.INDEX_NAME = s.INDEX_NAME
WHERE 
    t.TABLE_SCHEMA = DATABASE()
ORDER BY 
    t.TABLE_NAME, s.INDEX_NAME, s.SEQ_IN_INDEX;

-- Identifica tabelas que podem se beneficiar de índices
SELECT 
    t.TABLE_SCHEMA as banco,
    t.TABLE_NAME as tabela,
    t.TABLE_ROWS as linhas,
    io.COUNT_READ as leituras,
    io.COUNT_WRITE as escritas,
    io.COUNT_FETCH as buscas,
    ROUND(io.COUNT_READ / GREATEST(t.TABLE_ROWS, 1), 2) as leituras_por_linha,
    CASE 
        WHEN t.TABLE_ROWS > 1000 AND io.COUNT_READ > 10000 AND io.COUNT_READ / GREATEST(t.TABLE_ROWS, 1) > 10 THEN 'ALTA'
        WHEN t.TABLE_ROWS > 500 AND io.COUNT_READ > 5000 AND io.COUNT_READ / GREATEST(t.TABLE_ROWS, 1) > 5 THEN 'MÉDIA'
        ELSE 'BAIXA'
    END as prioridade_indexacao
FROM 
    information_schema.TABLES t
JOIN 
    performance_schema.table_io_waits_summary_by_table io ON t.TABLE_SCHEMA = io.OBJECT_SCHEMA AND t.TABLE_NAME = io.OBJECT_NAME
WHERE 
    t.TABLE_SCHEMA = DATABASE()
    AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY 
    leituras_por_linha DESC;

-- --------------------------------------------------------
-- 4. Análise de Bloqueios e Contenção
-- --------------------------------------------------------

-- Identifica bloqueios no banco de dados
SELECT 
    r.trx_id as id_transacao_solicitante,
    r.trx_mysql_thread_id as thread_solicitante,
    r.trx_query as consulta_solicitante,
    b.trx_id as id_transacao_bloqueando,
    b.trx_mysql_thread_id as thread_bloqueando,
    b.trx_query as consulta_bloqueando,
    b.trx_started as inicio_transacao,
    b.trx_tables_locked as tabelas_bloqueadas,
    TIMESTAMPDIFF(SECOND, b.trx_started, NOW()) as tempo_bloqueio_segundos
FROM 
    information_schema.innodb_lock_waits w
JOIN 
    information_schema.innodb_trx b ON b.trx_id = w.blocking_trx_id
JOIN 
    information_schema.innodb_trx r ON r.trx_id = w.requesting_trx_id;

-- Estatísticas de contenção de threads
SELECT 
    event_name as evento, 
    count_star as total_ocorrencias,
    sum_timer_wait / 1000000000000 as tempo_total_espera_segundos,
    avg_timer_wait / 1000000000 as tempo_medio_espera_ms,
    max_timer_wait / 1000000000 as tempo_maximo_espera_ms
FROM 
    performance_schema.events_waits_summary_global_by_event_name
WHERE 
    event_name LIKE 'wait/io/file/%'
    OR event_name LIKE 'wait/lock/%'
ORDER BY 
    sum_timer_wait DESC
LIMIT 20;

-- --------------------------------------------------------
-- 5. Análise de Utilização de Memória
-- --------------------------------------------------------

-- Análise do buffer pool do InnoDB
SELECT 
    pool_id as id_pool,
    pool_size as tamanho_pool,
    free_buffers as buffers_livres,
    database_pages as paginas_banco,
    old_database_pages as paginas_antigas,
    modified_database_pages as paginas_modificadas,
    pending_reads as leituras_pendentes,
    pending_writes as escritas_pendentes,
    pages_read as paginas_lidas,
    pages_created as paginas_criadas,
    pages_written as paginas_escritas
FROM 
    information_schema.INNODB_BUFFER_POOL_STATS;

-- --------------------------------------------------------
-- 6. Recomendações de Otimização
-- --------------------------------------------------------

-- Análise de variáveis de configuração críticas
SELECT 
    variable_name as variavel,
    variable_value as valor,
    CASE variable_name
        WHEN 'innodb_buffer_pool_size' THEN CONCAT('Recomendado: ', ROUND(@@total_memory * 0.7 / 1024 / 1024 / 1024, 2), ' GB (70% da memória total)')
        WHEN 'innodb_log_file_size' THEN 'Recomendado: 25% do buffer pool size'
        WHEN 'max_connections' THEN 'Avaliar com base no uso: SHOW STATUS LIKE "Max_used_connections"'
        WHEN 'query_cache_size' THEN 'Desativado em MySQL 8.0+, use o cache de consultas do aplicativo'
        WHEN 'innodb_flush_log_at_trx_commit' THEN 'Valor 1 para ACID completo, 2 para melhor performance'
        WHEN 'innodb_flush_method' THEN 'O_DIRECT geralmente é melhor para servidores dedicados'
        WHEN 'tmp_table_size' THEN 'Aumentar se muitas tabelas temporárias em disco'
        WHEN 'join_buffer_size' THEN 'Aumentar se muitas operações de join sem índice'
        ELSE ''
    END as recomendacao
FROM 
    performance_schema.global_variables
WHERE 
    variable_name IN (
        'innodb_buffer_pool_size', 
        'innodb_log_file_size', 
        'max_connections', 
        'query_cache_size', 
        'innodb_flush_log_at_trx_commit', 
        'innodb_flush_method', 
        'tmp_table_size', 
        'join_buffer_size'
    )
ORDER BY 
    variable_name;

-- --------------------------------------------------------
-- 7. Otimização Periódica
-- --------------------------------------------------------

-- Script para otimização periódica do banco
DELIMITER //

CREATE PROCEDURE sp_otimizacao_periodica()
BEGIN
    DECLARE banco VARCHAR(255);
    DECLARE tabela VARCHAR(255);
    DECLARE fragmentacao DECIMAL(10,2);
    DECLARE done INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR
        SELECT 
            table_schema, 
            table_name, 
            ROUND((data_free / (data_length + index_length)) * 100, 2) as fragmentacao_percentual
        FROM 
            information_schema.tables
        WHERE 
            table_schema = DATABASE()
            AND table_type = 'BASE TABLE'
            AND engine = 'InnoDB'
            AND (data_free / (data_length + index_length)) * 100 > 10;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Registra início da otimização
    SELECT CONCAT('Iniciando otimização - ', NOW()) as mensagem;
    
    -- Atualiza estatísticas das tabelas
    SELECT 'Atualizando estatísticas...' as mensagem;
    ANALYZE TABLE categorias, clientes, produtos, vendas, itens_venda;
    
    -- Otimiza tabelas fragmentadas
    SELECT 'Verificando tabelas fragmentadas...' as mensagem;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO banco, tabela, fragmentacao;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SELECT CONCAT('Otimizando tabela ', tabela, ' (fragmentação: ', fragmentacao, '%)') as mensagem;
        SET @sql = CONCAT('OPTIMIZE TABLE ', banco, '.', tabela);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;
    
    CLOSE cur;
    
    -- Registra conclusão da otimização
    SELECT CONCAT('Otimização concluída - ', NOW()) as mensagem;
END//

DELIMITER ;

-- Exemplo de uso da procedure de otimização
-- CALL sp_otimizacao_periodica(); 