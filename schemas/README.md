# 🗄️ Esquemas de Banco de Dados Otimizados

Esta pasta contém os esquemas de banco de dados otimizados que demonstram minhas habilidades em modelagem e estruturação de dados.

## 📁 Conteúdo

- `schema.sql` - Esquema principal do banco de dados com tabelas, relacionamentos, índices e triggers
- `modelo_otimizado.md` - Documentação detalhada sobre as decisões de modelagem e otimizações

## 🚀 Características Principais

### Particionamento Eficiente
O esquema implementa particionamento de tabela por data, melhorando drasticamente a performance para tabelas com grande volume de dados (10.550+ registros).

### Normalização Estratégica
Foi aplicada normalização até a 3ª forma normal em pontos estratégicos, enquanto algumas desnormalizações controladas foram implementadas para melhorar a performance.

### Campos Calculados
Uso de campos calculados (como `subtotal` em `itens_venda`) para evitar recálculos frequentes e garantir consistência.

### Triggers Otimizados
Implementação de triggers para manter a integridade referencial e automatizar atualizações sem comprometer a performance.

### Índices Estratégicos
Criação de índices simples e compostos baseados em análise de padrões de acesso aos dados.

## 🔍 Como Utilizar

1. Execute o script `schema.sql` em uma instância MySQL 8.0+
2. Os scripts criam automaticamente toda a estrutura necessária
3. Veja o arquivo `modelo_otimizado.md` para entender as decisões de design

## 📋 Melhorias de Performance

O esquema foi projetado para suportar:
- Mais de 10.000 registros com performance excelente
- Crescimento projetado de até 100.000 registros sem degradação
- Consultas complexas otimizadas para execução rápida
- Operações de escrita com mínimo impacto em leituras concorrentes 