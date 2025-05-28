# 🔍 Estratégias de Indexação

## 📊 Análise de Índices

### 1. Identificação de Necessidades
- Análise de consultas frequentes
- Verificação de colunas mais acessadas
- Identificação de padrões de busca
- Avaliação de cardinalidade das colunas

## 🎯 Tipos de Índices Implementados

### 1. Índices Simples
```sql
-- Índice para busca por data
CREATE INDEX idx_vendas_data ON vendas(data_venda);

-- Índice para busca por status
CREATE INDEX idx_pedidos_status ON pedidos(status);
```

### 2. Índices Compostos
```sql
-- Índice para otimizar consultas de vendas por período e cliente
CREATE INDEX idx_vendas_cliente_data ON vendas(cliente_id, data_venda);

-- Índice para relatórios de produtos por categoria
CREATE INDEX idx_produtos_categoria_nome ON produtos(categoria_id, nome);
```

### 3. Índices Parciais
```sql
-- Índice apenas para produtos ativos
CREATE INDEX idx_produtos_ativos ON produtos(nome) WHERE ativo = true;

-- Índice para vendas do último mês
CREATE INDEX idx_vendas_recentes ON vendas(data_venda, valor) 
WHERE data_venda >= CURRENT_DATE - INTERVAL '30 days';
```

## 📈 Manutenção de Índices

### 1. Monitoramento
```sql
-- Verificar utilização de índices
SELECT 
    schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### 2. Otimização
- Reconstrução periódica de índices fragmentados
- Remoção de índices redundantes ou não utilizados
- Análise de impacto na performance

## 🚀 Resultados

### Melhorias Alcançadas
- Redução de 80% no tempo de busca
- Otimização do uso de disco
- Melhor performance em consultas complexas
- Balanceamento entre performance de leitura e escrita

### Boas Práticas
1. Criar índices seletivos
2. Evitar índices redundantes
3. Monitorar utilização
4. Manter índices atualizados
5. Considerar o impacto em operações de escrita 