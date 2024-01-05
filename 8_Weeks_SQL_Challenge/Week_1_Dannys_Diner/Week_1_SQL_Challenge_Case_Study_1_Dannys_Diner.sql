/*  --------------------
    Case Study Questions
    --------------------*/
-- Phu Nguyen
-- PostgreSQL

-- 1. What is the total amount each customer spent at the restaurant?
    select
        s.customer_id,
        sum(m.price) as total_amount
    from dannys_diner.sales s
    left join dannys_diner.menu m
    on s.product_id = m.product_id
    group by s.customer_id;
-- 2. How many days has each customer visited the restaurant?
    select
        s.customer_id,
        count(distinct s.order_date) as visited_days
    from dannys_diner.sales s
    group by s.customer_id;
-- 3. What was the first item from the menu purchased by each customer?
    with min_item as
    (select 
    s.customer_id,
    s.product_id,
    row_number() over(partition by s.customer_id order by order_date) as rn
    from dannys_diner.sales s
    )
    select
        mi.customer_id,
        m.product_name
    from min_item mi
    left join dannys_diner.menu m
    on mi.product_id = m.product_id
    where mi.rn = 1;
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
    with count_item as(
    select 
        s.product_id,
        count(s.order_date) as order_times
    from dannys_diner.sales s
    group by s.product_id
    order by count(s.order_date) desc
    )
    select 
        ci.product_id,
        m.product_name
    from count_item ci
    left join dannys_diner.menu m on ci.product_id = m.product_id
    limit 1;
-- 5. Which item was the most popular for each customer?
    with most_item as
    (select 
        s.customer_id,
        s.product_id,
        rank() over (partition by s.customer_id order by count(s.product_id) desc) as most_item
    from dannys_diner.sales s
    group by s.customer_id, s.product_id
    )
    select
        mi.customer_id,
        m.product_name
    from most_item mi
    left join dannys_diner.menu m on mi.product_id = m.product_id
    where mi.most_item = 1;
-- 6. Which item was purchased first by the customer after they became a member?
    with first_item as
    (select
        s.customer_id,
        m.product_name,
        row_number() over(partition by s.customer_id order by s.order_date) as rn
    from dannys_diner.sales s
    left join dannys_diner.menu m on s.product_id = m.product_id
    left join dannys_diner.members mb on s.customer_id = mb.customer_id
    where s.order_date > mb.join_date)
    select 	
        customer_id,
        product_name
    from first_item
    where rn = 1;
-- 7. Which item was purchased just before the customer became a member?
    with first_item as
    (select
        s.customer_id,
        m.product_name,
        row_number() over(partition by s.customer_id order by s.order_date) as rn
    from dannys_diner.sales s
    left join dannys_diner.menu m on s.product_id = m.product_id
    left join dannys_diner.members mb on s.customer_id = mb.customer_id
    where s.order_date < mb.join_date)
    select 	
        customer_id,
        product_name
    from first_item
    where rn = 1;
-- 8. What is the total items and amount spent for each member before they became a member?
    select
        s.customer_id,
        count(s.product_id) as quantity,
        sum(m.price) as amount
    from dannys_diner.sales s
    left join dannys_diner.menu m on s.product_id = m.product_id
    left join dannys_diner.members mb on s.customer_id = mb.customer_id
    where s.order_date < mb.join_date
    group by s.customer_id;
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
    with points_table as
    (select 
        m.product_id,
        case m.product_id 
            when 1 then m.price*20
            else m.price*10
        end as points
    from dannys_diner.menu m
    )
    select
        s.customer_id,
        sum(pt.points) as total_points
    from dannys_diner.sales s
    left join points_table pt on s.product_id = pt.product_id
    group by s.customer_id;
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
    with valid_date as
    (select
        mb.customer_id,
        mb.join_date,
        mb.join_date + interval '6 day' as valid_date, 
        date_trunc('month', mb.join_date) + interval '1 month' - interval '1 day' as end_of_january
    from dannys_diner.members mb
    )
    select 
        s.customer_id,
        sum(case when m.product_id = 1 then m.price*20
            when s.order_date between vd.join_date and vd.valid_date then m.price*20
            else m.price*10
        end) as total_point
    from dannys_diner.sales s
    left join valid_date vd on s.customer_id = vd.customer_id
    left join dannys_diner.menu m on s.product_id = m.product_id
    where s.order_date <= end_of_january
    group by s.customer_id;