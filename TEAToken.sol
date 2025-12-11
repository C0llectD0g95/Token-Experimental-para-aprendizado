// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title Token Experimental para Aprendizado (TEA)
 * @dev Implementação do token TEA com 6 casas decimais, governança integrada e controle de inflação anual.
 * Baseado na documentação de Arquitetura Tokenômica v1.0.
 */
contract TEAToken is ERC20, ERC20Burnable, AccessControl, ERC20Permit, ERC20Votes {
    
    // Definição de Roles para controle de acesso granular
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Constantes Tokenômicas
    // Emissão anual fixa de 500.000 TEA 
    uint256 public constant ANNUAL_INFLATION_AMOUNT = 500_000 * 10**6; 
    
    // Supply Inicial de 10.000.000 TEA 
    uint256 public constant INITIAL_SUPPLY = 10_000_000 * 10**6;

    // Variável de estado para controlar a periodicidade da inflação
    uint256 public nextInflationTimestamp;

    event InflationMinted(address indexed to, uint256 amount);

    constructor(address defaultAdmin, address minter)
        ERC20("Token Experimental para Aprendizado", "TEA") // [cite: 12]
        ERC20Permit("Token Experimental para Aprendizado")
    {
        // Configuração de Casas Decimais é feita no override da função decimals() abaixo para 6 

        // Concede permissões iniciais
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);

        // Mint do Supply Gênese (10 Milhões) para o admin distribuir conforme alocação
        // A distribuição (Fundo Educacional, Staking, etc.) deve ser feita pós-deploy
        _mint(defaultAdmin, INITIAL_SUPPLY);

        // Define a próxima data de inflação para 1 ano após o deploy
        nextInflationTimestamp = block.timestamp + 365 days;
    }

    /**
     * @dev Sobrescreve a função decimals para retornar 6, conforme especificação técnica.
     * Isso simplifica a leitura de saldos e reduz complexidade visual.
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @dev Função para executar a emissão inflacionária linear constante.
     * Apenas endereços com MINTER_ROLE podem chamar (ex: Tesouraria DAO ou TimeCore).
     * Libera 500.000 TEA a cada 365 dias[cite: 23, 24].
     * @param to Endereço que receberá os novos tokens (ex: contrato de Fundo Educacional).
     */
    function mintAnnualInflation(address to) external onlyRole(MINTER_ROLE) {
        require(block.timestamp >= nextInflationTimestamp, "TEA: Inflacao anual ainda nao disponivel");
        
        // Atualiza o timestamp para o próximo ano
        nextInflationTimestamp += 365 days; // Mantém a periodicidade linear baseada na data original

        _mint(to, ANNUAL_INFLATION_AMOUNT);
        emit InflationMinted(to, ANNUAL_INFLATION_AMOUNT);
    }

    // As funções abaixo são overrides obrigatórios para integrar ERC20, Votes e AccessControl

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}