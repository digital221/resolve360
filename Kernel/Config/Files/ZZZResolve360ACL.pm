package Kernel::Config::Files::ZZZResolve360ACL;

use strict;
use warnings;
no warnings 'redefine';
use utf8;

sub Load {
    my ($File, $Self) = @_;

    # ACL-01: Restrict Financial Resolution / Approval state for high amount claims (>= 100 000 FCFA)
    # Only agents with 'approbateurs' group rw permission can set ticket state to 'clos (résolu)' or 'clos (remboursé)' when amount >= 100k
    $Self->{TicketAcl}->{'ACL-Resolve360-FinancialApproval-Restriction'} = {
        'PossibleNot' => {
            'Ticket' => {
                'State' => ['clos (résolu)', 'clos (remboursé)', 'closed successful'],
            },
        },
        'Properties' => {
            'User' => {
                'Group_rw' => ['[Not]approbateurs'],
            },
            'DynamicField' => {
                'Resolve360_FinancialImpact' => ['[1-9][0-9]{5,}', '[1-9][0-9]{6,}'],
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
                'Group_rw' => ['[Not]conformite', '[Not]approbateurs'],
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
