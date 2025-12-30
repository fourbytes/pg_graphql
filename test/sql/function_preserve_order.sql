begin;
    create table item(
        id serial primary key,
        name text not null,
        rank int not null
    );

    insert into item(name, rank) values
        ('alpha', 3),
        ('beta', 1),
        ('gamma', 2);

    -- Function with explicit ORDER BY that we want to preserve
    create function search_items()
        returns setof item
        language sql stable
    as $$ select * from item order by rank asc; $$;

    comment on function search_items is '@graphql({"preserveOrder": true})';

    -- Test 1: No orderBy arg - should preserve function order (rank asc: beta=1, gamma=2, alpha=3)
    select jsonb_pretty(graphql.resolve($$
        {
            searchItems {
                edges {
                    node {
                        name
                        rank
                    }
                }
            }
        }
    $$));

    -- Test 2: With explicit orderBy arg - should override with user-specified order
    select jsonb_pretty(graphql.resolve($$
        {
            searchItems(orderBy: [{name: DescNullsLast}]) {
                edges {
                    node {
                        name
                        rank
                    }
                }
            }
        }
    $$));

    -- Test 3: Function WITHOUT preserveOrder directive - should use default PK order
    create function search_items_default()
        returns setof item
        language sql stable
    as $$ select * from item order by rank asc; $$;

    select jsonb_pretty(graphql.resolve($$
        {
            searchItemsDefault {
                edges {
                    node {
                        name
                        rank
                    }
                }
            }
        }
    $$));

rollback;
