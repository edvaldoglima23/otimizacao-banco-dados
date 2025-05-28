-- --------------------------------------------------------
-- Otimização de Índices para MySQL
-- Implementação prática das estratégias de indexação
-- --------------------------------------------------------

-- --------------------------------------------------------
-- 1. Análise de Índices Existentes
-- --------------------------------------------------------

-- Script para identificar índices não utilizados
-- Execute periodicamente para monitorar a utilização de índices
/*
SELECT 
    t.TABLE_SCHEMA,
    t.TABLE_NAME,
    s.INDEX_NAME,
    s.COLUMN_NAME,
    s.SEQ_IN_INDEX,
    i.NON_UNIQUE,
    CASE 
        WHEN h.COUNT_STAR IS NULL THEN 'Nunca utilizado'
        WHEN h.COUNT_STAR < 10 THEN 'Pouco utilizado'
        ELSE 'Utilizado'
    END as utilizacao,
    IFNULL(h.COUNT_STAR, 0) as vezes_utilizado
FROM information_schema.STATISTICS s
JOIN information_schema.TABLES t ON s.TABLE_SCHEMA = t.TABLE_SCHEMA AND s.TABLE_NAME = t.TABLE_NAME
JOIN information_schema.STATISTICS i ON s.TABLE_SCHEMA = i.TABLE_SCHEMA AND s.TABLE_NAME = i.TABLE_NAME AND s.INDEX_NAME = i.INDEX_NAME
LEFT JOIN performance_schema.table_io_waits_summary_by_index_usage h 
    ON h.OBJECT_SCHEMA = s.TABLE_SCHEMA AND h.OBJECT_NAME = s.TABLE_NAME AND h.INDEX_NAME = s.INDEX_NAME
WHERE t.TABLE_SCHEMA = 'nome_do_seu_banco'
ORDER BY t.TABLE_NAME, s.INDEX_NAME, s.SEQ_IN_INDEX;
*/

-- --------------------------------------------------------
-- 2. Criação de Índices Estratégicos
-- --------------------------------------------------------

-- Os índices a seguir foram planejados com base em:
-- 1. Análise de consultas frequentes
-- 2. Padrões de acesso identificados
-- 3. Seletividade das colunas
-- 4. Balanceamento entre performance de leitura e escrita

-- Índices para tabela de clientes
-- Otimiza consultas por segmento e última compra
CREATE INDEX idx_clientes_segmento ON clientes(segmento);
CREATE INDEX idx_clientes_ultima_compra ON clientes(ultima_compra);

-- Índices para tabela de produtos
-- Otimiza consultas por categoria e status
CREATE INDEX idx_produtos_categoria ON produtos(categoria_id);
CREATE INDEX idx_produtos_ativo ON produtos(ativo);
CREATE INDEX idx_produtos_categoria_preco ON produtos(categoria_id, preco DESC);

-- Índices para tabela de vendas
-- Otimiza consultas por período, cliente e status
CREATE INDEX idx_vendas_data ON vendas(data_venda);
CREATE INDEX idx_vendas_cliente ON vendas(cliente_id);
CREATE INDEX idx_vendas_status ON vendas(status);
CREATE INDEX idx_vendas_cliente_data ON vendas(cliente_id, data_venda);

-- Índices para tabela de itens de venda
-- Otimiza consultas de produtos mais vendidos
CREATE INDEX idx_itens_venda_produto ON itens_venda(produto_id);
CREATE INDEX idx_itens_venda_venda_produto ON itens_venda(venda_id, produto_id);

-- --------------------------------------------------------
-- 3. Manutenção de Índices
-- --------------------------------------------------------

-- Script para otimizar tabelas e reconstruir índices
-- Execute periodicamente para manter a performance
OPTIMIZE TABLE clientes, produtos, categorias, vendas, itens_venda;

-- Script para análise de tabelas - atualiza estatísticas usadas pelo otimizador
ANALYZE TABLE clientes, produtos, categorias, vendas, itens_venda;

-- --------------------------------------------------------
-- 4. Avaliação de Consultas com EXPLAIN
-- --------------------------------------------------------

-- Exemplo de análise de plano de execução para identificar oportunidades de otimização
EXPLAIN
SELECT 
    c.nome,
    COUNT(v.id) as total_pedidos,
    SUM(v.valor_total) as valor_total
FROM vendas v
JOIN clientes c ON v.cliente_id = c.id
WHERE v.data_venda BETWEEN '2023-01-01' AND '2023-12-31'
  AND c.segmento = 'PREMIUM'
GROUP BY c.id, c.nome
ORDER BY valor_total DESC
LIMIT 100;

-- Analisando comportamento de índices em consultas com EXPLAIN FORMAT=JSON
-- Isso fornece informações detalhadas sobre o uso de índices
EXPLAIN FORMAT=JSON
SELECT 
    p.nome,
    cat.categoria,
    SUM(iv.quantidade) as quantidade_vendida
FROM itens_venda iv
JOIN produtos p ON iv.produto_id = p.id
JOIN categorias cat ON p.categoria_id = cat.id
WHERE p.ativo = 1
GROUP BY p.id, p.nome, cat.categoria
ORDER BY quantidade_vendida DESC
LIMIT 20;

-- --------------------------------------------------------
-- 5. Índices Parciais e Otimizações Avançadas
-- --------------------------------------------------------

-- No MySQL 8.0+, podemos usar índices funcionais
-- Otimiza consultas que filtram por ano/mês da venda
CREATE INDEX idx_vendas_ano_mes ON vendas((EXTRACT(YEAR_MONTH FROM data_venda)));

-- Índice para otimizar a ordenação de produtos por popularidade
CREATE INDEX idx_produtos_popularidade ON produtos(
    (SELECT COUNT(*) FROM itens_venda iv WHERE iv.produto_id = produtos.id)
);

-- Índice para facilitar a busca de produtos com estoque baixo
CREATE INDEX idx_produtos_estoque_baixo ON produtos(estoque, nome)
COMMENT 'Otimizado para alertas de estoque baixo';

-- --------------------------------------------------------
-- 6. Monitoramento de Performance de Índices
-- --------------------------------------------------------

-- Script para identificar os índices mais utilizados
SELECT 
    OBJECT_SCHEMA as banco_de_dados,
    OBJECT_NAME as tabela,
    INDEX_NAME as indice,
    COUNT_STAR as total_acessos,
    COUNT_READ as leituras,
    COUNT_WRITE as escritas,
    COUNT_FETCH as buscas
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE INDEX_NAME IS NOT NULL
  AND OBJECT_SCHEMA = 'nome_do_seu_banco'
ORDER BY COUNT_STAR DESC
LIMIT 20;

-- Script para identificar tabelas com varreduras completas frequentes
SELECT 
    t.TABLE_SCHEMA,
    t.TABLE_NAME,
    t.TABLE_ROWS,
    t.AVG_ROW_LENGTH,
    ROUND((t.DATA_LENGTH + t.INDEX_LENGTH) / 1024 / 1024, 2) as tamanho_mb,
    h.COUNT_READ as leituras_totais,
    h.COUNT_FETCH as buscas
FROM information_schema.TABLES t
JOIN performance_schema.table_io_waits_summary_by_table h 
    ON h.OBJECT_SCHEMA = t.TABLE_SCHEMA AND h.OBJECT_NAME = t.TABLE_NAME
WHERE t.TABLE_SCHEMA = 'nome_do_seu_banco'
  AND t.TABLE_ROWS > 1000
  AND h.COUNT_READ > 1000
ORDER BY h.COUNT_READ DESC
LIMIT 20; 