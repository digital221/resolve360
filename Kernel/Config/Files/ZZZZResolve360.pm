# --
# Kernel/Config/Files/ZZZZResolve360.pm - Absolute Final Overrides for Resolve360 Banking
# Loaded AFTER ZZZAAuto.pm (Alphabetical order ZZZZ > ZZZA)
# --

package Kernel::Config::Files::ZZZZResolve360;

use strict;
use warnings;
no warnings 'redefine';
use utf8;

sub Load {
    my ($File, $Self) = @_;

    # Core Branding
    $Self->{'ProductName'} = 'Resolve360';
    $Self->{'Organization'} = 'Digital Factory SN';
    $Self->{'AdminEmail'} = 'support@digitalfactory.sn';

    # Default Language
    $Self->{'DefaultLanguage'} = 'fr';
    $Self->{'CustomerDefaultLanguage'} = 'fr';

    # Skins
    push @{ $Self->{'Loader::Customer::CommonCSS'}->{'000-Framework'} }, 'resolve360.css';
    push @{ $Self->{'Loader::Agent::CommonCSS'}->{'000-Framework'} }, 'resolve360.css';

    # ================================================================
    # HIDE IT SUPPORT FIELDS FROM CUSTOMER FORM (CustomerTicketMessage)
    # ================================================================
    $Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'TicketType'} = 0; # HIDE Type
    $Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'Service'}    = 0; # HIDE Service
    $Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'SLA'}        = 0; # HIDE SLA
    $Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'Priority'}   = 0; # HIDE Priority
    $Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'StateDefault'} = 'new';

    # BANKING DYNAMIC FIELDS ON CUSTOMER FORM
    $Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'DynamicField'} = {
        'Resolve360_Agency'        => 2, # Required
        'Resolve360_ClientType'    => 1,
        'Resolve360_Category'      => 2, # Required
        'Resolve360_SubCategory'   => 1,
        'Resolve360_AccountNo'     => 1,
        'Resolve360_Amount'        => 1,
        'Resolve360_TransactionID' => 1,
        'Resolve360_MaskedCard'    => 1,
        'Resolve360_TxnDate'       => 1,
        'Resolve360_MerchantName'  => 1,
        'MotifReclamation'         => 1,
        'MontantLitige'            => 1,
        'CanalOrigine'             => 1,
        'NumeroCompte'             => 1,
    };

    # FULL AGENT WORKSPACE FIELDS
    $Self->{'Ticket::Frontend::AgentTicketZoom'}->{'DynamicField'} = {
        'Resolve360_CIF'              => 1,
        'Resolve360_ClientType'       => 1,
        'Resolve360_Agency'           => 1,
        'Resolve360_OriginChannel'    => 1,
        'Resolve360_Product'          => 1,
        'Resolve360_Category'         => 1,
        'Resolve360_SubCategory'      => 1,
        'Resolve360_AccountNo'        => 1,
        'Resolve360_MaskedCard'       => 1,
        'Resolve360_TransactionID'    => 1,
        'Resolve360_TxnDate'          => 1,
        'Resolve360_Amount'           => 1,
        'Resolve360_Currency'         => 1,
        'Resolve360_ATMID'            => 1,
        'Resolve360_MerchantName'     => 1,
        'Resolve360_Channel'          => 1,
        'Resolve360_FinancialImpact'  => 1,
        'Resolve360_ReputationalRisk' => 1,
        'Resolve360_RootCause'        => 1,
        'Resolve360_Decision'         => 1,
    };

    return 1;
}

1;
