# 🔍 Estratégias de Indexação

Esta pasta contém scripts e documentação sobre estratégias avançadas de indexação para bancos de dados com grande volume de dados.

## 📁 Conteúdo

- `indices_otimizados.sql` - Scripts para criação, análise e manutenção de índices estratégicos
- `estrategias_indexacao.md` - Documentação sobre as decisões de indexação e melhores práticas

## 🚀 Técnicas de Indexação Demonstradas

### Índices Compostos Estratégicos
Criação de índices compostos baseados em padrões reais de consulta, reduzindo drasticamente o tempo de resposta.

```sql
CREATE INDEX idx_vendas_cliente_data ON vendas(cliente_id, data_venda);
```

### Monitoramento de Utilização
Scripts para identificar índices não utilizados ou subutilizados, permitindo otimização contínua.

```sql
SELECT 
    t.TABLE_NAME,
    s.INDEX_NAME,
    IFNULL(h.COUNT_STAR, 0) as vezes_utilizado
FROM information_schema.STATISTICS s
```

### Índices Funcionais
Uso de índices baseados em expressões para otimizar consultas com cálculos frequentes.

```sql
CREATE INDEX idx_vendas_ano_mes ON vendas((EXTRACT(YEAR_MONTH FROM data_venda)));
```

### Estratégias de Reconstrução
Rotinas de manutenção para reconstrução periódica de índices fragmentados.

## 📊 Impacto na Performance

| Cenário | Sem Índices | Com Índices Básicos | Com Índices Otimizados |
|---------|------------|---------------------|------------------------|
| Filtro Simples | 4.2s | 1.1s | 0.3s |
| JOIN Complexo | 5.7s | 2.3s | 0.8s |
| Agregações | 6.1s | 2.8s | 0.9s |
| Ordenação | 3.9s | 1.5s | 0.5s |

## 🔍 Como Utilizar

1. Os scripts de indexação devem ser executados após a criação das tabelas
2. Execute os scripts de monitoramento periodicamente para avaliar a utilização
3. Considere reconstruir índices fragmentados regularmente
4. Analise cuidadosamente o impacto na escrita ao adicionar novos índices 