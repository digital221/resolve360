package Kernel::Config::Files::ZZZResolve360ACL;

use strict;
use warnings;
no warnings 'redefine';
use utf8;

sub Load {
    my ($File, $Self) = @_;

    # ACL-01: Restrict Financial Resolution / Approval state for high amount claims (> 100 000 FCFA)
    # Only agents with the 'approbateurs' group can set ticket state to 'clos (résolu)' or 'clos (remboursé)' when amount > 100k
    $Self->{TicketAcl}->{'ACL-Resolve360-FinancialApproval-Restriction'} = {
        'PossibleNot' => {
            'Ticket' => {
                'State' => ['clos (résolu)', 'clos (remboursé)', 'closed successful'],
            },
        },
        'PossibleNotAdd' => {},
        'Properties' => {
            'User' => {
                'Group_Responsibility' => {
                    'approbateurs' => [ '0' ], # Agent does NOT belong to approbateurs group
                },
            },
            'DynamicField' => {
                'Resolve360_FinancialImpact' => ['[1-9][0-9]{5,}', '[1-9][0-9]{6,}'], # Amount >= 100,000
            },
        },
        'StopAfterMatch' => 0,
    };

    # ACL-02: Restrict Fraud & High Reputational Risk closure to Conformité Officers & Approvers
    $Self->{TicketAcl}->{'ACL-Resolve360-FraudComplianceClosure-Restriction'} = {
        'PossibleNot' => {
            'Ticket' => {
                'State' => ['clos (résolu)', 'closed successful'],
            },
        },
        'Properties' => {
            'User' => {
                'Group_Responsibility' => {
                    'conformite' => [ '0' ],
                    'approbateurs' => [ '0' ],
                },
            },
            'Queue' => {
                'Name' => ['Conformité', 'Fraude'],
            },
        },
        'StopAfterMatch' => 0,
    };

    return 1;
}

1;
