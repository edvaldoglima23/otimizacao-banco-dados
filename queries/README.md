# 🔍 Consultas SQL Otimizadas

Esta pasta contém exemplos práticos de consultas SQL otimizadas para alta performance em bancos com grande volume de dados.

## 📁 Conteúdo

- `consultas_otimizadas.sql` - Coleção de consultas com versões originais e otimizadas, incluindo benchmarks
- `otimizacoes_consultas.md` - Documentação detalhada sobre técnicas de otimização aplicadas

## 🚀 Técnicas de Otimização Demonstradas

### Common Table Expressions (CTEs)
Uso de CTEs para materializar resultados intermediários, reduzindo o processamento repetitivo e melhorando a legibilidade.

```sql
WITH vendas_periodo AS (
    SELECT id FROM vendas 
    WHERE data_venda BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT * FROM vendas_periodo...
```

### Eliminação de Subqueries
Substituição de subqueries por JOINs mais eficientes, reduzindo o tempo de execução em até 87%.

### Indexação Estratégica
Consultas projetadas para aproveitar ao máximo os índices disponíveis, evitando varreduras de tabela completas.

### Limites e Filtros Antecipados
Aplicação de filtros e limites o mais cedo possível na execução da consulta para reduzir o conjunto de dados processado.

### Uso de Funções Nativas Otimizadas
Substituição de funções custosas por alternativas mais eficientes (ex: `EXTRACT` em vez de `DATE_FORMAT`).

## 📊 Melhorias de Performance

| Consulta | Versão Original | Versão Otimizada | Melhoria |
|----------|----------------|-----------------|----------|
| Relatório de Vendas | 3.2s | 0.3s | 91% |
| Produtos Mais Vendidos | 4.7s | 0.8s | 83% |
| Análise por Período | 3.5s | 0.6s | 83% |
| Perfil de Cliente | 5.2s | 0.7s | 87% |
| Análise de Estoque | 4.1s | 0.5s | 88% |

## 🔍 Como Utilizar

1. As consultas foram testadas no MySQL 8.0+
2. Os comentários explicam cada técnica de otimização aplicada
3. Cada consulta inclui a versão original para comparação
4. Execute com EXPLAIN para ver como o otimizador de consultas as processa 